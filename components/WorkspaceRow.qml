import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

// Hyprland workspaces; the active one is a wide pill.
Row {
	id: root

	spacing: 4
	property real pillHeight: 28
	// shrink inactive pills so the row never exceeds this width
	property real maxWidth: 100000
	readonly property real inactiveW: Math.max(14, Math.min(pillHeight, (maxWidth - pillHeight * 1.6 - spacing * (count - 1)) / Math.max(1, count - 1)))
	// only show focused, visible-on-a-monitor and occupied workspaces
	property bool filtered: false
	readonly property var ids: {
		if (filtered) {
			const set = new Set();
			if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0)
				set.add(Hyprland.focusedWorkspace.id);
			for (const m of Hyprland.monitors.values)
				if (m.activeWorkspace && m.activeWorkspace.id > 0)
					set.add(m.activeWorkspace.id);
			for (const t of Hyprland.toplevels.values)
				if (t.workspace && t.workspace.id > 0)
					set.add(t.workspace.id);
			return Array.from(set).sort((a, b) => a - b);
		}
		let m = 5;
		for (const w of Hyprland.workspaces.values)
			m = Math.max(m, w.id);
		const n = Math.min(m, 10);
		return Array.from({ length: n }, (_, i) => i + 1);
	}
	readonly property int count: ids.length
	readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

	Repeater {
		model: root.ids

		Rectangle {
			id: pill
			required property int modelData
			readonly property int wsId: modelData
			readonly property bool active: root.activeId === wsId
			readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)

			height: root.pillHeight
			width: active ? root.pillHeight * 1.6 : root.pillHeight
			radius: Theme.st.pill ? (active ? root.pillHeight * 0.43 : root.pillHeight / 2) : Theme.pillRadius(root.pillHeight)
			color: active ? Theme.primary : occupied ? Theme.secondaryContainer : Theme.surfaceContainerHigh

			Behavior on width {
				SpringAnimation {
					spring: Theme.springBouncy
					damping: Theme.dampBouncy
					epsilon: 0.5
				}
			}
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

			Txt {
				anchors.centerIn: parent
				text: pill.wsId
				font.pixelSize: 13
				font.weight: pill.active ? Font.Bold : Font.Medium
				color: pill.active ? Theme.primaryFg : pill.occupied ? Theme.secondaryContainerFg : Theme.surfaceVariantFg
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: Hypr.focusWorkspace(pill.wsId)
			}
		}
	}
}
