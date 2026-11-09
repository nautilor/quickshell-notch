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

	implicitHeight: 28
	implicitWidth: row.implicitWidth + (label !== "" ? 18 : 12)
	radius: mouse.pressed ? 8 : height / 2
	color: active ? Theme.primaryContainer : mouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
	Behavior on radius {
		NumberAnimation {
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
			font.pixelSize: 12
			font.weight: Font.Medium
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
