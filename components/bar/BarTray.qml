import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.config

// Tray icons: left click activates, middle click secondary action, right click shows the app menu.
Row {
	id: root
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("tray", cfg)
	readonly property real cell: c.size

	spacing: 2

	Repeater {
		model: SystemTray.items

		Rectangle {
			id: cell
			required property var modelData

			width: root.cell
			height: root.cell
			radius: mouse.pressed ? 6 : root.cell / 2
			color: mouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"

			Image {
				anchors.centerIn: parent
				width: Math.round(root.cell * 0.7)
				height: width
				sourceSize: Qt.size(64, 64)
				source: cell.modelData.icon
				fillMode: Image.PreserveAspectFit
			}
			MouseArea {
				id: mouse
				anchors.fill: parent
				hoverEnabled: true
				acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
				cursorShape: Qt.PointingHandCursor
				onClicked: event => {
					if (event.button === Qt.MiddleButton)
						cell.modelData.secondaryActivate();
					else if (event.button === Qt.RightButton || cell.modelData.onlyMenu) {
						if (cell.modelData.hasMenu) {
							const p = cell.mapToItem(null, 0, cell.height);
							cell.modelData.display(QsWindow.window, p.x, p.y);
						}
					} else {
						cell.modelData.activate();
					}
				}
			}
		}
	}
}
