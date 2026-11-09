import QtQuick
import Quickshell
import qs.services
import qs.components

// Runs a shell command.
BarButton {
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("command", cfg)
	icon: c.icon
	label: c.label
	onClicked: {
		if (c.command !== "")
			Quickshell.execDetached(["sh", "-c", c.command]);
	}
}
