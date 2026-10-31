import QtQuick
import Quickshell
import qs.config
import qs.services

// One dock slot: app icon (with running dot), separator, "add" button or trash.
Item {
	id: root

	required property var info
	property real size: 44
	property bool vertical: false
	property string edge: "bottom"
	// pointer position along the dock axis (in the parent's coordinates), -1 when not hovering
	property real mouseAxis: -1
	property bool menuOpen: false

	readonly property real cell: size + 14
	readonly property real along: info.type === "sep" ? 14 : cell
	readonly property real center: (vertical ? y : x) + along / 2
	readonly property real bump: mouseAxis < 0 || info.type === "sep" ? 0 : Math.max(0, 1 - Math.abs(mouseAxis - center) / (cell * 2.2))
	readonly property real zoom: 1 + 0.45 * bump
	readonly property bool hovered: area.containsMouse
	readonly property string label: info.type === "app" ? info.name : info.type === "add" ? "Add app" : info.type === "trash" ? (Dock.trashCount > 0 ? "Trash (" + Dock.trashCount + ")" : "Trash") : ""

	signal clicked
	signal middleClicked
	signal menuRequested
	signal filesDropped(var paths)

	width: vertical ? cell : along
	height: vertical ? along : cell
	z: hovered ? 10 : 0

	// separator
	Rectangle {
		visible: root.info.type === "sep"
		anchors.centerIn: parent
		width: root.vertical ? root.cell * 0.6 : 2
		height: root.vertical ? 2 : root.cell * 0.6
		radius: 1
		color: Theme.outlineVariant
	}

	// icon; grows towards the inside of the screen
	Item {
		id: icon
		visible: root.info.type !== "sep"
		anchors.centerIn: parent
		width: root.size
		height: root.size
		scale: root.zoom
		transformOrigin: root.edge === "top" ? Item.Top : root.edge === "bottom" ? Item.Bottom : root.edge === "left" ? Item.Left : Item.Right
		Behavior on scale {
			NumberAnimation {
				duration: 70
			}
		}

		Image {
			visible: root.info.type === "app"
			anchors.fill: parent
			sourceSize: Qt.size(root.size * 2, root.size * 2)
			asynchronous: true
			source: root.info.type === "app" ? Quickshell.iconPath(root.info.icon, "application-x-executable") : ""
		}

		Rectangle {
			visible: root.info.type === "add" || root.info.type === "trash"
			anchors.fill: parent
			radius: root.size * 0.28
			color: drop.containsDrag ? Theme.primaryContainer : Theme.surfaceContainerHigh
			Icon {
				anchors.centerIn: parent
				name: root.info.type === "add" ? "add" : Dock.trashCount > 0 ? "delete_sweep" : "delete"
				size: root.size * 0.55
				color: drop.containsDrag ? Theme.primaryContainerFg : Theme.surfaceVariantFg
			}
		}
	}

	// running indicator, on the screen-edge side of the slot
	Rectangle {
		visible: root.info.type === "app" && root.info.windows.length > 0
		width: 5
		height: 5
		radius: 2.5
		color: Theme.primary
		x: root.vertical ? (root.edge === "left" ? 1 : root.width - width - 1) : (root.width - width) / 2
		y: root.vertical ? (root.height - height) / 2 : (root.edge === "top" ? 1 : root.height - height - 1)
	}

	// name bubble on the inner side
	Rectangle {
		id: tip
		visible: root.hovered && !root.menuOpen && root.label !== ""
		width: tipText.implicitWidth + 20
		height: tipText.implicitHeight + 12
		radius: height / 2
		color: Theme.surfaceContainerHigh
		readonly property real reach: root.size * root.zoom + 8
		x: root.vertical ? (root.edge === "left" ? (root.cell - root.size) / 2 + reach : (root.cell + root.size) / 2 - reach - width) : (root.width - width) / 2
		y: root.vertical ? (root.height - height) / 2 : (root.edge === "top" ? (root.cell - root.size) / 2 + reach : (root.cell + root.size) / 2 - reach - height)
		Txt {
			id: tipText
			anchors.centerIn: parent
			text: root.label
			font.pixelSize: 12
			elide: Text.ElideNone
		}
	}

	DropArea {
		id: drop
		anchors.fill: parent
		enabled: root.info.type === "trash"
		keys: ["text/uri-list"]
		onDropped: d => {
			const paths = d.urls.map(u => decodeURIComponent(u.toString().replace(/^file:\/\//, "")));
			if (paths.length > 0)
				root.filesDropped(paths);
		}
	}

	MouseArea {
		id: area
		anchors.fill: parent
		enabled: root.info.type !== "sep"
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
		cursorShape: Qt.PointingHandCursor
		onClicked: m => {
			if (m.button === Qt.RightButton)
				root.menuRequested();
			else if (m.button === Qt.MiddleButton)
				root.middleClicked();
			else
				root.clicked();
		}
	}
}
