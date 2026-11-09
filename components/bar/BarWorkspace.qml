import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.components

// Current workspace number in a chip.
Rectangle {
	id: chip
	property var cfg: ({})
	readonly property var workspace: Hyprland.focusedWorkspace

	width: Math.max(24, wsText.implicitWidth + 14)
	height: 24
	radius: 8
	color: Theme.primaryContainer

	Txt {
		id: wsText
		anchors.centerIn: parent
		text: chip.workspace ? (chip.workspace.name || chip.workspace.id) : "–"
		color: Theme.primaryContainerFg
		font.pixelSize: 13
		font.weight: Font.Bold
	}
	Connections {
		target: Hyprland
		function onFocusedWorkspaceChanged() {
			bump.restart();
		}
	}
	SequentialAnimation {
		id: bump
		NumberAnimation {
			target: chip
			property: "scale"
			to: 0.7
			duration: 70
		}
		NumberAnimation {
			target: chip
			property: "scale"
			to: 1
			duration: 380
			easing.type: Easing.OutBack
			easing.overshoot: 3
		}
	}
	MouseArea {
		anchors.fill: parent
		onWheel: w => Hyprland.dispatch(w.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
	}
}
