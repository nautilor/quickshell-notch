import QtQuick
import qs.config

// Switch sized and shaped by the UI style. Expressive / Material: thumb with a check/close icon that grows on press.
// Others: a plain round thumb (white for macOS and GNOME, Fluent-style outlined track for Windows 11).
Item {
	id: root

	property bool checked: false
	signal toggled(bool value)

	implicitWidth: Theme.switchW
	implicitHeight: Theme.switchH

	Rectangle {
		anchors.fill: parent
		radius: height / 2
		color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
		border.width: root.checked ? 0 : (Theme.fancySwitch ? 2 : Theme.controlBorder)
		border.color: Theme.outline
		Behavior on color {
			ColorAnimation {
				duration: Theme.durShort
			}
		}
	}

	Rectangle {
		id: thumb
		readonly property real small: Theme.fancySwitch ? 18 : root.height - 2 * Theme.switchInset
		readonly property real big: Theme.fancySwitch ? root.height - 8 : small
		property real size: root.checked ? big : small
		width: mouse.pressed && Theme.fancySwitch ? size + 6 : size
		height: size
		radius: height / 2
		anchors.verticalCenter: parent.verticalCenter
		x: root.checked ? parent.width - width - (Theme.fancySwitch ? 4 : Theme.switchInset) : (Theme.fancySwitch ? 7 - (size - 18) / 2 : Theme.switchInset)
		color: Theme.switchWhiteKnob ? "#ffffff" : root.checked ? Theme.primaryFg : Theme.outline

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
			visible: Theme.fancySwitch && (root.checked || thumb.size > 16)
		}
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: root.toggled(!root.checked)
	}
}
