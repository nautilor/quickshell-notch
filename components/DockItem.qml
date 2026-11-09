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
	readonly property real along: info.type === "sep" ? 14 : info.type === "widget" ? info.cells * cell - 6 : cell
	readonly property real center: (vertical ? y : x) + along / 2
	readonly property real bump: dragging ? 0.6 : mouseAxis < 0 || info.type === "sep" || info.type === "widget" ? 0 : Math.max(0, 1 - Math.abs(mouseAxis - center) / (cell * 2.2))
	readonly property real zoom: 1 + 0.45 * bump
	readonly property bool hovered: area.containsMouse
	readonly property string label: info.type === "app" ? info.name : info.type === "folder" ? info.name : info.type === "add" ? "Add app" : info.type === "trash" ? (Dock.trashCount > 0 ? "Trash (" + Dock.trashCount + ")" : "Trash") : ""

	// pinned apps can be dragged along the dock; the parent decides the new slot from the final offset
	property real dragOffset: 0
	property bool dragging: false
	property bool moved: false
	// slide out of the way (in px along the axis) while another icon is dragged past
	property real shift: 0
	Behavior on shift {
		NumberAnimation {
			duration: 160
			easing.type: Easing.OutCubic
		}
	}

	signal clicked
	signal dragMoved(real offset)
	signal dragReleased(real offset)
	signal middleClicked
	signal menuRequested
	signal filesDropped(var paths)

	width: vertical ? cell : along
	height: vertical ? along : cell
	z: dragging ? 20 : hovered ? 10 : 0
	transform: Translate {
		x: root.vertical ? 0 : root.dragOffset + root.shift
		y: root.vertical ? root.dragOffset + root.shift : 0
	}

	// separator
	Rectangle {
		visible: root.info.type === "sep"
		anchors.centerIn: parent
		width: root.vertical ? root.cell * 0.6 : 2
		height: root.vertical ? 2 : root.cell * 0.6
		radius: 1
		color: Theme.outlineVariant
	}

	// dock widget (media, clock, ...): sits above the mouse area, so its own controls get the clicks while the
	// rest of the tile still drags / opens the context menu through the area underneath
	Loader {
		id: widgetLoader
		z: 1
		active: root.info.type === "widget"
		anchors.centerIn: parent
		width: root.width - 8
		height: root.cell - 6
		source: root.info.type === "widget" ? root.info.source : ""
		onLoaded: item.cfg = root.info.cfg
	}

	// icon; grows towards the inside of the screen
	Item {
		id: icon
		visible: root.info.type !== "sep" && root.info.type !== "widget"
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
			source: root.info.type === "app" ? Dock.iconSource(root.info.key, root.info.icon) : ""
		}

		Image {
			visible: root.info.type === "folder"
			anchors.fill: parent
			sourceSize: Qt.size(root.size * 2, root.size * 2)
			asynchronous: true
			source: root.info.type === "folder" ? Dock.iconSource(root.info.key, root.info.icon) : ""
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
		visible: root.hovered && !root.menuOpen && !root.dragging && root.label !== "" && !(root.info.type === "app" && root.info.windows.length > 0)
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

	// Widgets contain their own mouse areas that would swallow the press, so dragging them uses a handler:
	// it watches passively and only takes over once the pointer actually moves.
	DragHandler {
		id: widgetDrag
		enabled: root.info.type === "widget"
		target: null
		acceptedButtons: Qt.LeftButton
		onTranslationChanged: {
			if (!active)
				return;
			const d = root.vertical ? translation.y : translation.x;
			if (root.dragging || Math.abs(d) > 8) {
				root.dragging = true;
				root.moved = true;
				root.dragOffset = d;
				root.dragMoved(d);
			}
		}
		onActiveChanged: {
			if (!active && root.dragging) {
				const d = root.dragOffset;
				root.dragging = false;
				root.dragOffset = 0;
				root.dragReleased(d);
			}
		}
	}

	MouseArea {
		id: area
		anchors.fill: parent
		enabled: root.info.type !== "sep"
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
		cursorShape: Qt.PointingHandCursor
		property real pressAxis: 0
		function axisOf(m) {
			const p = area.mapToItem(root.parent, m.x, m.y);
			return root.vertical ? p.y : p.x;
		}
		onPressed: m => {
			pressAxis = axisOf(m);
			root.moved = false;
		}
		onPositionChanged: m => {
			if (!pressed || !root.info.pinned || root.info.type === "widget" || !(pressedButtons & Qt.LeftButton))
				return;
			const d = axisOf(m) - pressAxis;
			if (root.dragging || Math.abs(d) > 8) {
				root.dragging = true;
				root.moved = true;
				root.dragOffset = d;
				root.dragMoved(d);
			}
		}
		onReleased: {
			if (root.dragging) {
				const d = root.dragOffset;
				root.dragging = false;
				root.dragOffset = 0;
				root.dragReleased(d);
			}
		}
		onClicked: m => {
			if (root.moved) {
				root.moved = false;
				return;
			}
			if (m.button === Qt.RightButton)
				root.menuRequested();
			else if (m.button === Qt.MiddleButton)
				root.middleClicked();
			else
				root.clicked();
		}
	}
}
