import QtQuick
import qs.config
import qs.services
import qs.components

// One quick toggle; which one is a setting.
Item {
	id: root

	property var cfg: ({})
	property bool editing: false

	readonly property var c: WidgetTypes.resolve("toggle", cfg)
	readonly property string kind: c.kind

	// wide enough for a chevron beside the label
	readonly property bool canConnect: kind === "wifi" || kind === "bluetooth"
	readonly property bool hasArrow: canConnect && width >= 150

	Btn {
		anchors.fill: parent
		vertical: true
		toggleable: true
		toggledRadius: 18
		idleRadius: 30
		iconSize: Math.max(20, Math.min(34, Math.min(parent.width, parent.height) * 0.36))
		icon: Toggles.icon(root.kind)
		label: root.c.label !== "" ? root.c.label : Toggles.label(root.kind)
		toggled: Toggles.on(root.kind)
		enabled: !root.editing
		onClicked: Toggles.toggle(root.kind)
		// no room for the arrow: right click opens the picker instead
		onRightClicked: if (root.canConnect)
			HomeLayout.connect = root.kind
	}

	// opens the connect panel
	MouseArea {
		visible: root.hasArrow
		enabled: !root.editing
		width: 40
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.right: parent.right
		cursorShape: Qt.PointingHandCursor
		onClicked: HomeLayout.connect = root.kind
		Icon {
			anchors.centerIn: parent
			name: "chevron_right"
			size: 22
			color: Toggles.on(root.kind) ? Theme.primaryFg : Theme.surfaceVariantFg
		}
	}
}
