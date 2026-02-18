import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasma5support as Plasma5Support
import "./Utils.js" as Utils

MouseArea {
    property int wheelDelta : 0

    acceptedButtons: Qt.MiddleButton
    //Open Grid View on middle Click
    onClicked: executable.connectSource(Utils.qdbusRun("org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component.invokeShortcut", ["Grid View"]))

    //Scroll Handler
    onWheel : wheel => {
        wheelDelta += wheel.angleDelta.y || wheel.angleDelta.x;
        let increment = 0;
        while (wheelDelta >= 120) {
            wheelDelta -= 120;
            increment++;
        }
        while (wheelDelta <= -120) {
            wheelDelta += 120;
            increment--;
        }
        while (increment !== 0) {
            if (increment < 0) {
                const count = virtualDesktopInfo.numberOfDesktops;
                const nextPage = cfg.wrapOn? (curr_page + 1) % count :
                Math.min(curr_page + 1, count - 1);
                virtualDesktopInfo.requestActivate(virtualDesktopInfo.desktopIds[nextPage]);
            } else {
                const count = virtualDesktopInfo.numberOfDesktops;
                const previousPage = cfg.wrapOn? (count + curr_page - 1) % count :
                Math.max(curr_page - 1, 0);
                virtualDesktopInfo.requestActivate(virtualDesktopInfo.desktopIds[previousPage]);
            }
            increment += (increment < 0) ? 1 : -1;
            wheelDelta = 0;
        }
    }
    Plasma5Support.DataSource {
        id: "executable"
        engine: "executable"
        connectedSources: []
        onNewData:function(sourceName, data){
            disconnectSource(sourceName)
        }
    }
}

