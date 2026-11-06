import QtQuick
import Quickshell
import Quickshell.Services.SystemTray as Tray
import "../../config" as Config
import "../../themes"

Row {
    id: root
    spacing: Theme.spacing.xs
    visible: repeater.count > 0

    Repeater {
        id: repeater
        model: Tray.SystemTray.items

        delegate: Item {
            id: trayItem
            required property var modelData

            readonly property var item: modelData
            readonly property bool hasIcon: item && item.icon !== ""

            width: Theme.buttonSize
            height: Theme.buttonSize

            Image {
                anchors.centerIn: parent
                width: Theme.trayIconSize
                height: Theme.trayIconSize
                visible: trayItem.hasIcon
                source: trayItem.item ? trayItem.item.icon : ""
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.centerIn: parent
                visible: !trayItem.hasIcon
                text: "\uf009"
                color: Theme.foreground
                font.family: Theme.iconFontFamily
                font.pixelSize: Theme.iconSize
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (!trayItem.item)
                        return;
                    if (mouse.button === Qt.RightButton) {
                        if (trayItem.item.hasMenu)
                            menuAnchor.open();
                        else
                            trayItem.item.secondaryActivate();
                    } else {
                        if (trayItem.item.onlyMenu && trayItem.item.hasMenu)
                            menuAnchor.open();
                        else
                            trayItem.item.activate();
                    }
                }
                onWheel: (wheel) => {
                    if (trayItem.item)
                        trayItem.item.scroll(wheel.angleDelta.y, false);
                }
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: trayItem.item ? trayItem.item.menu : null
                anchor.item: trayItem
                anchor.edges: Config.Settings.barPosition === "bottom" ? Edges.Top : Edges.Bottom
                anchor.gravity: Config.Settings.barPosition === "bottom" ? Edges.Top : Edges.Bottom
                anchor.adjustment: PopupAdjustment.SlideX
            }
        }
    }
}
