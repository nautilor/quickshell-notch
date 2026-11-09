import QtQuick
import qs.config
import qs.services
import qs.components

// Unread notification count; click opens the notifications tab.
Item {
	id: root
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("notifications", cfg)

	visible: Notifs.count > 0 || c.alwaysShow
	implicitWidth: Notifs.count > 0 ? Math.max(18, countText.implicitWidth + 10) : 18
	implicitHeight: 18
	width: implicitWidth
	height: implicitHeight

	Rectangle {
		visible: Notifs.count > 0
		anchors.fill: parent
		radius: 9
		color: Theme.tertiaryContainer
		Txt {
			id: countText
			anchors.centerIn: parent
			text: Notifs.count
			font.pixelSize: 11
			font.weight: Font.Bold
			color: Theme.tertiaryContainerFg
		}
	}
	Icon {
		visible: Notifs.count === 0
		anchors.centerIn: parent
		name: "notifications"
		size: 18
		color: Theme.surfaceVariantFg
	}
	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: NotchCtl.toggle("notifications")
	}
}
