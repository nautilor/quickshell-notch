import QtQuick
import qs.config
import qs.services
import qs.components

// Unread notification count; click opens the notifications tab.
Rectangle {
	id: root
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("notifications", cfg)

	visible: Notifs.count > 0 || c.alwaysShow
	implicitWidth: Notifs.count > 0 ? Math.max(32, countRow.implicitWidth + 20) : 32
	implicitHeight: 32
	width: implicitWidth
	height: implicitHeight
	radius: mouse.pressed ? Theme.radiusInner : Notifs.count > 0 ? 12 : height / 2
	color: Notifs.count > 0 ? Theme.tertiaryContainer : mouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
	Behavior on radius {
		SpringAnimation {
			spring: Theme.springBouncy
			damping: Theme.dampBouncy
			epsilon: 0.25
		}
	}
	Behavior on color {
		ColorAnimation {
			duration: Theme.durShort
		}
	}

	Row {
		id: countRow
		anchors.centerIn: parent
		spacing: 4
		Icon {
			name: Notifs.count > 0 ? "notifications_active" : "notifications"
			size: 18
			fill: Notifs.count > 0 ? 1 : 0
			color: Notifs.count > 0 ? Theme.tertiaryContainerFg : Theme.surfaceVariantFg
			anchors.verticalCenter: parent.verticalCenter
		}
		Txt {
			visible: Notifs.count > 0
			text: Notifs.count
			font.pixelSize: 13
			font.weight: Font.Bold
			color: Theme.tertiaryContainerFg
			anchors.verticalCenter: parent.verticalCenter
		}
	}
	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: NotchCtl.toggle("notifications")
	}
}
