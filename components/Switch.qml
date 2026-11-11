import QtQuick
import qs.config

// M3 Expressive switch: pill track, thumb carries a check/close icon and stretches on press.
Item {
	id: root

	property bool checked: false
	signal toggled(bool value)

	implicitWidth: 56
	implicitHeight: 34

	Rectangle {
		anchors.fill: parent
		radius: height / 2
		color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
		border.width: root.checked ? 0 : 2
		border.color: Theme.outline
		Behavior on color {
			ColorAnimation {
				duration: Theme.durShort
			}
		}
	}

	Rectangle {
		id: thumb
		property real size: root.checked ? 26 : 18
		width: mouse.pressed ? size + 6 : size
		height: size
		radius: height / 2
		anchors.verticalCenter: parent.verticalCenter
		x: root.checked ? parent.width - width - 4 : 7 - (size - 18) / 2
		color: root.checked ? Theme.primaryFg : Theme.outline

		Behavior on x {
			SpringAnimation {
				spring: Theme.springBouncy
				damping: Theme.dampBouncy
				epsilon: 0.25
			}
		}
		Behavior on size {
			SpringAnimation {
				spring: Theme.springBouncy
				damping: Theme.dampBouncy
				epsilon: 0.25
			}
		}
		Behavior on width {
			NumberAnimation {
				duration: Theme.durShort
			}
		}
		Behavior on color {
			ColorAnimation {
				duration: Theme.durShort
			}
		}

		Icon {
			anchors.centerIn: parent
			name: root.checked ? "check" : "close"
			size: 14
			color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
			visible: root.checked || thumb.size > 16
		}
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: root.toggled(!root.checked)
	}
}
