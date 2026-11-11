import QtQuick
import qs.config

// Small icon (+ optional label) button used by the full bar.
Rectangle {
	id: root

	property string icon
	property string label
	property color fg: Theme.surfaceVariantFg
	property bool active: false
	signal clicked

	implicitHeight: 32
	implicitWidth: Math.max(32, row.implicitWidth + (label !== "" ? 24 : 14))
	radius: mouse.pressed ? Theme.radiusInner : active ? 12 : height / 2
	color: active ? Theme.primaryContainer : mouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
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
		id: row
		anchors.centerIn: parent
		spacing: 6
		Icon {
			visible: root.icon !== ""
			name: root.icon
			size: 18
			fill: root.active ? 1 : 0
			color: root.active ? Theme.primaryContainerFg : root.fg
			anchors.verticalCenter: parent.verticalCenter
		}
		Txt {
			visible: root.label !== ""
			text: root.label
			font.pixelSize: 13
			font.weight: Font.DemiBold
			elide: Text.ElideNone
			color: root.active ? Theme.primaryContainerFg : root.fg
			anchors.verticalCenter: parent.verticalCenter
		}
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
