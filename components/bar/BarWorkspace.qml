import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

// Current workspace number in a chip.
Rectangle {
	id: chip
	property var cfg: ({})
	readonly property var workspace: Hyprland.focusedWorkspace

	width: Math.max(32, wsText.implicitWidth + 18)
	height: 32
	radius: 12
	color: Theme.primaryContainer

	Txt {
		id: wsText
		anchors.centerIn: parent
		text: chip.workspace ? (chip.workspace.name || chip.workspace.id) : "–"
		color: Theme.primaryContainerFg
		font.pixelSize: 14
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
		onWheel: w => Hypr.focusWorkspace(w.angleDelta.y > 0 ? "e-1" : "e+1")
	}
}
