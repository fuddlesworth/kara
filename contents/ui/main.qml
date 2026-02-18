import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import org.kde.activities as Activities
import org.kde.kirigami as Kirigami
import "./Utils.js" as Utils

PlasmoidItem {
    id: root
    preferredRepresentation     : fullRepresentation
    property var cfg            : plasmoid.configuration
    property var location       : plasmoid.location
    property var form           : plasmoid.formFactor
    property bool is_vertical   : form == PlasmaCore.Types.Vertical
    property int curr_page      : Math.max(0, virtualDesktopInfo.position(virtualDesktopInfo.currentDesktop))
    property var customLabels   : cfg.labelsList.split('\n')
    property var customIcons    : cfg.iconsList.split('\n')
    property bool showOnlyActive: cfg.showOnlyActive

    clip: false

    //Scrolling should change the page/desktop/workspace
    ScrllHndl{ anchors.fill: parent }

    // Virtual desktop and Tasks Models (required)
    TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }

    Plasma5Support.DataSource {
        id: dbusExecutable
        engine: "executable"
        connectedSources: []
        onNewData: disconnectSource(sourceName)
    }
    function activateDesktop(pos) {
        dbusExecutable.connectSource(Utils.qdbusActivateDesktop(virtualDesktopInfo.desktopIds[pos]))
    }
    TaskManager.ActivityInfo { id: activityInfo }
    Activities.ActivityInfo { id: fullActivityInfo; activityId: ":current" }

    //Only this will be visible to the user
    fullRepresentation: GridLayout {
        columnSpacing: is_vertical ? 0 : cfg.spacing
        rowSpacing: is_vertical ? cfg.spacing : 0
        columns: is_vertical ? 1 : virtualDesktopInfo.numberOfDesktops
        rows: is_vertical ? virtualDesktopInfo.numberOfDesktops : 1
        Repeater {
            id: rep
            model: virtualDesktopInfo.numberOfDesktops
            delegate: RepresentationRectangle {}
            onItemAdded: function(index,item){
                item.pos = index
            }
        }
    }

    //Contextual (Right-Click menu) actions
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add Virtual Desktop")
            icon.name: "list-add"
            visible: KConfig.KAuthorized.authorize("kcm_kwin_virtualdesktops")
            onTriggered: dbusExecutable.connectSource(
                Utils.qdbusCommand("createDesktop", [
                    virtualDesktopInfo.numberOfDesktops,
                    i18n("Desktop %1", virtualDesktopInfo.numberOfDesktops + 1)
                ])
            )
        },
        PlasmaCore.Action {
            text: i18n("Remove Virtual Desktop")
            icon.name: "list-remove"
            visible: KConfig.KAuthorized.authorize("kcm_kwin_virtualdesktops")
            enabled: virtualDesktopInfo.numberOfDesktops > 1
            onTriggered: dbusExecutable.connectSource(
                Utils.qdbusCommand("removeDesktop", [String(virtualDesktopInfo.currentDesktop)])
            )
        },
        PlasmaCore.Action {
            text: i18n("Configure Virtual Desktops…")
            icon.name: "systemsettings"
            visible: KConfig.KAuthorized.authorize("kcm_kwin_virtualdesktops")
            onTriggered: KCM.KCMLauncher.openSystemSettings("kcm_kwin_virtualdesktops")
        }
    ]
}
