import QtQuick
import qs.config

// Tonal pill that groups the content of one full-bar widget (end-4 style).
Rectangle {
	id: root

	default property alias content: holder.data
	property real padding: 12
	property bool hoverable: false
	property bool hovered: false
	property color fill: Theme.surfaceContainerHigh

	implicitHeight: 32
	implicitWidth: holder.childrenRect.width + padding * 2
	radius: Theme.pillRadius(height)
	border.width: Theme.controlBorder
	border.color: Theme.outlineVariant
	color: hoverable && hovered ? Theme.surfaceContainerHighest : fill
	Behavior on color {
		ColorAnimation {
			duration: Theme.durShort
		}
	}

	Item {
		id: holder
		anchors.centerIn: parent
		width: childrenRect.width
		height: parent.height
	}
}
