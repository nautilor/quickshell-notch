import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

PanelWindow {
	id: win

	required property var modelData
	screen: modelData

	readonly property string edge: Settings.dockEdge
	readonly property bool vertical: edge === "left" || edge === "right"
	readonly property real iconSize: Settings.dockIconSize
	readonly property real cell: iconSize + 14
	readonly property real thickness: cell + 8
	readonly property real margin: 8

	// spans the whole edge so menus and zoomed icons have room; the mask keeps the rest click-through
	anchors.top: edge !== "bottom"
	anchors.bottom: edge !== "top"
	anchors.left: edge !== "right"
	anchors.right: edge !== "left"
	implicitWidth: 560
	implicitHeight: 560
	color: "transparent"
	exclusionMode: Settings.dockAutohide ? ExclusionMode.Ignore : ExclusionMode.Normal
	exclusiveZone: Settings.dockAutohide ? 0 : thickness + 2 * margin
	mask: Region {
		item: win.menuKind !== "" ? full : hit
		Region {
			item: preview
		}
	}

	WlrLayershell.namespace: "dock"
	WlrLayershell.layer: WlrLayer.Top
	WlrLayershell.keyboardFocus: (menuKind === "add" || menuKind === "icon") ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

	// ---- popup menu state ----
	property string menuKind: ""      // "" | "app" | "trash" | "add"
	property var menuItem: null
	property point menuAnchor: Qt.point(0, 0)
	property int armed: -1

	// drag-to-reorder: the slot being dragged and where it would land among the pinned apps
	property string dragKey: ""
	property int dragFrom: -1
	property int dragTo: -1

	function openMenu(kind, info, slot) {
		const p = slot.mapToItem(root, slot.width / 2, slot.height / 2);
		menuAnchor = Qt.point(p.x, p.y);
		menuItem = info;
		armed = -1;
		menuKind = kind;
		if (kind === "add") {
			pickerField.text = "";
			Qt.callLater(() => pickerField.forceFocus());
		}
	}
	function closeMenu() {
		menuKind = "";
	}

	// ---- window previews (hover a running app) ----
	property string previewKey: ""
	property point previewAnchor: Qt.point(0, 0)
	readonly property var previewWindows: {
		if (previewKey === "")
			return [];
		for (const i of Dock.items)
			if (i.type === "app" && i.key === previewKey)
				return i.windows;
		return [];
	}
	readonly property bool previewShown: previewKey !== "" && previewWindows.length > 0 && menuKind === "" && dragKey === ""
	function showPreview(info, slot) {
		previewTimer.stop();
		const p = slot.mapToItem(root, slot.width / 2, slot.height / 2);
		previewAnchor = Qt.point(p.x, p.y);
		previewKey = info.key;
	}
	function hidePreview() {
		previewTimer.restart();
	}
	Timer {
		id: previewTimer
		interval: 250
		onTriggered: win.previewKey = ""
	}

	// popup placement next to the dock, centred on the slot that opened it
	function popX(w, anchor) {
		const a = anchor ?? menuAnchor;
		return vertical ? (edge === "left" ? bar.x + bar.width + 10 : bar.x - w - 10) : Math.max(8, Math.min(root.width - w - 8, a.x - w / 2));
	}
	function popY(h, anchor) {
		const a = anchor ?? menuAnchor;
		return vertical ? Math.max(8, Math.min(root.height - h - 8, a.y - h / 2)) : (edge === "top" ? bar.y + bar.height + 10 : bar.y - h - 10);
	}

	function openIconEditor() {
		const cur = (Settings.dockIcons || {})[menuItem.key] || "";
		iconField.text = cur;
		menuKind = "icon";
		iconPop.browsing = false;
		Qt.callLater(() => iconField.forceFocus());
	}
	function applyIcon(value) {
		Dock.setIcon(menuItem.key, value);
		closeMenu();
	}

	readonly property var menuRows: {
		const it = menuItem;
		const r = [];
		if (menuKind === "app" && it) {
			if (it.windows.length > 1) {
				for (const w of it.windows)
					r.push({ label: w.title || it.name, act: () => Dock.focus(w) });
				r.push({ sep: true });
			}
			r.push({ label: it.windows.length > 0 ? "New window" : "Open", act: () => Dock.launch(it.entry) });
			r.push({ label: "Change icon…", keep: true, act: () => win.openIconEditor() });
			if (it.entry)
				r.push({ label: it.pinned ? "Remove from Dock" : "Keep in Dock", act: () => it.pinned ? Dock.unpin(it.key) : Dock.pin(it.key) });
			if (it.windows.length > 0)
				r.push({ label: it.windows.length > 1 ? "Quit all windows" : "Quit", danger: true, act: () => Dock.closeAll(it.windows) });
		} else if (menuKind === "trash") {
			r.push({ label: "Open Trash", act: () => Dock.openTrash() });
			r.push({ label: "Empty Trash", confirm: "Click again to empty", danger: true, enabled: Dock.trashCount > 0, act: () => Dock.emptyTrash() });
		}
		return r;
	}

	// ---- autohide ----
	property bool hidden: false
	readonly property bool wantHidden: Settings.dockAutohide && !hover.hovered && menuKind === ""
	onWantHiddenChanged: {
		if (wantHidden)
			hideTimer.restart();
		else
			hidden = false;
	}
	Timer {
		id: hideTimer
		interval: 700
		onTriggered: win.hidden = win.wantHidden
	}

	FocusScope {
		id: root
		anchors.fill: parent
		focus: true
		Keys.onEscapePressed: win.closeMenu()

		HoverHandler {
			id: hover
		}

		Item {
			id: full
			anchors.fill: parent
		}

		// input area: the dock plus some slack (only a thin strip while hidden)
		Item {
			id: hit
			width: win.vertical ? (win.hidden ? 6 : win.thickness + win.margin + 8) : bar.width + 20
			height: win.vertical ? bar.height + 20 : (win.hidden ? 6 : win.thickness + win.margin + 8)
			x: win.edge === "left" ? 0 : win.edge === "right" ? root.width - width : (root.width - width) / 2
			y: win.edge === "top" ? 0 : win.edge === "bottom" ? root.height - height : (root.height - height) / 2
		}

		// click outside closes the menu
		MouseArea {
			anchors.fill: parent
			enabled: win.menuKind !== ""
			acceptedButtons: Qt.AllButtons
			onPressed: win.closeMenu()
		}

		Rectangle {
			id: bar
			property real slide: win.hidden ? win.margin + win.thickness - 3 : 0
			Behavior on slide {
				SpringAnimation {
					spring: Theme.springSoft
					damping: Theme.dampSoft
					epsilon: 0.5
				}
			}
			readonly property real length: (win.vertical ? grid.implicitHeight : grid.implicitWidth) + 16
			width: win.vertical ? win.thickness : length
			height: win.vertical ? length : win.thickness
			radius: Math.min(width, height) * 0.36
			color: Theme.notch
			border.width: 1
			border.color: Theme.outlineVariant
			x: win.edge === "left" ? win.margin - slide : win.edge === "right" ? root.width - width - win.margin + slide : (root.width - width) / 2
			y: win.edge === "top" ? win.margin - slide : win.edge === "bottom" ? root.height - height - win.margin + slide : (root.height - height) / 2

			Grid {
				id: grid
				anchors.centerIn: parent
				flow: win.vertical ? Grid.TopToBottom : Grid.LeftToRight
				rows: win.vertical ? 1000 : 1
				columns: win.vertical ? 1 : 1000

				HoverHandler {
					id: gridHover
				}

				Repeater {
					id: slots
					model: Dock.items
					DockItem {
						id: slot
						required property var modelData
						required property int index
						onHoveredChanged: {
							if (hovered && info.type === "app" && info.windows.length > 0 && !dragging && win.menuKind === "")
								win.showPreview(info, slot);
							else if (!hovered && win.previewKey === info.key)
								win.hidePreview();
						}
						shift: {
							if (win.dragKey === "" || !info.pinned || info.key === win.dragKey)
								return 0;
							if (win.dragFrom < win.dragTo && index > win.dragFrom && index <= win.dragTo)
								return -(win.vertical ? height : width);
							if (win.dragFrom > win.dragTo && index >= win.dragTo && index < win.dragFrom)
								return win.vertical ? height : width;
							return 0;
						}
						function targetFor(offset) {
							const c = center + offset;
							let target = 0;
							for (let i = 0; i < slots.count; i++) {
								const o = slots.itemAt(i);
								if (o && o !== slot && o.info.type === "app" && o.info.pinned && o.center < c)
									target++;
							}
							return target;
						}
						onDragMoved: offset => {
							win.previewKey = "";
							win.dragKey = info.key;
							win.dragFrom = index;
							win.dragTo = targetFor(offset);
						}						info: modelData
						size: win.iconSize
						vertical: win.vertical
						edge: win.edge
						menuOpen: win.menuKind !== ""
						mouseAxis: gridHover.hovered ? (win.vertical ? gridHover.point.position.y : gridHover.point.position.x) : -1
						onClicked: {
							win.closeMenu();
							win.previewKey = "";
							if (info.type === "app")
								Dock.activate(info);
							else if (info.type === "add")
								win.openMenu("add", info, slot);
							else if (info.type === "trash")
								Dock.openTrash();
						}
						onMiddleClicked: if (info.type === "app")
							Dock.launch(info.entry)
						onMenuRequested: {
							if (info.type === "app" || info.type === "trash")
								win.openMenu(info.type, info, slot);
						}
						onFilesDropped: paths => Dock.trash(paths)
						onDragReleased: offset => {
							const target = targetFor(offset);
							win.dragKey = "";
							Dock.move(info.key, target);
						}
					}
				}
			}
		}

		// ---- window previews ----
		Rectangle {
			id: preview
			visible: win.previewShown
			readonly property real cardW: 200
			readonly property real cardH: 125
			readonly property int perLine: Math.max(1, Math.min(win.previewWindows.length, Math.floor(((win.vertical ? root.width - win.thickness - 40 : root.width - 32) - 12) / (cardW + 8))))
			width: perLine * (cardW + 8) - 8 + 24
			height: Math.ceil(win.previewWindows.length / perLine) * (cardH + 28 + 8) - 8 + 24
			radius: Theme.radiusMedium
			color: Theme.surfaceContainerHigh
			border.width: 1
			border.color: Theme.outlineVariant
			x: win.popX(width, win.previewAnchor)
			y: win.popY(height, win.previewAnchor)

			HoverHandler {
				onHoveredChanged: {
					if (hovered)
						previewTimer.stop();
					else
						win.hidePreview();
				}
			}

			Flow {
				anchors.fill: parent
				anchors.margins: 12
				spacing: 8

				Repeater {
					model: win.previewShown ? win.previewWindows : []
					Rectangle {
						id: card
						required property var modelData
						width: preview.cardW
						height: preview.cardH + 28
						radius: Theme.radiusSmall
						color: cardArea.containsMouse ? Theme.secondaryContainer : "transparent"

						Txt {
							id: cardTitle
							anchors.left: parent.left
							anchors.right: parent.right
							anchors.top: parent.top
							anchors.margins: 6
							font.pixelSize: 12
							elide: Text.ElideRight
							text: card.modelData.title || ""
						}
						ScreencopyView {
							anchors.left: parent.left
							anchors.right: parent.right
							anchors.top: cardTitle.bottom
							anchors.bottom: parent.bottom
							anchors.margins: 6
							anchors.topMargin: 4
							captureSource: card.modelData
							live: true
							constraintSize: Qt.size(preview.cardW * 2, preview.cardH * 2)
						}
						MouseArea {
							id: cardArea
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								Dock.focus(card.modelData);
								win.previewKey = "";
							}
						}
					}
				}
			}
		}

		// ---- context menu ----
		Rectangle {
			id: menu
			visible: win.menuRows.length > 0 && (win.menuKind === "app" || win.menuKind === "trash")
			width: 220
			height: menuCol.implicitHeight + 12
			radius: Theme.radiusMedium
			color: Theme.surfaceContainerHigh
			border.width: 1
			border.color: Theme.outlineVariant
			x: win.popX(width)
			y: win.popY(height)

			Column {
				id: menuCol
				anchors.fill: parent
				anchors.margins: 6
				spacing: 2

				Repeater {
					model: win.menuRows
					Item {
						id: row
						required property var modelData
						required property int index
						readonly property bool armed: win.armed === index
						width: menuCol.width
						height: modelData.sep ? 9 : 36
						opacity: modelData.enabled === false ? 0.4 : 1

						Rectangle {
							visible: row.modelData.sep === true
							anchors.centerIn: parent
							width: parent.width - 16
							height: 1
							color: Theme.outlineVariant
						}
						Rectangle {
							visible: !row.modelData.sep
							anchors.fill: parent
							radius: Theme.radiusSmall
							color: rowArea.containsMouse && row.modelData.enabled !== false ? (row.modelData.danger ? Theme.errorContainer : Theme.secondaryContainer) : "transparent"
							Txt {
								anchors.left: parent.left
								anchors.right: parent.right
								anchors.leftMargin: 12
								anchors.rightMargin: 12
								anchors.verticalCenter: parent.verticalCenter
								text: row.armed ? row.modelData.confirm : (row.modelData.label ?? "")
								color: row.modelData.danger ? Theme.error : Theme.surfaceFg
							}
						}
						MouseArea {
							id: rowArea
							anchors.fill: parent
							enabled: !row.modelData.sep && row.modelData.enabled !== false
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								if (row.modelData.confirm && !row.armed) {
									win.armed = row.index;
									return;
								}
								row.modelData.act();
								if (!row.modelData.keep)
									win.closeMenu();
							}
						}
					}
				}
			}
		}

		// ---- add-app picker ----
		Rectangle {
			id: picker
			visible: win.menuKind === "add"
			width: 300
			height: 340
			radius: Theme.radiusMedium
			color: Theme.surfaceContainerHigh
			border.width: 1
			border.color: Theme.outlineVariant
			x: win.popX(width)
			y: win.popY(height)

			readonly property var results: win.menuKind === "add" ? Apps.search(pickerField.text).filter(a => Dock.pinned.indexOf(a.id) < 0) : []

			Field {
				id: pickerField
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				anchors.margins: 8
				icon: "search"
				placeholder: "Add to Dock"
				onAccepted: {
					const a = picker.results[0];
					if (a) {
						Dock.pin(a.id);
						win.closeMenu();
					}
				}
			}
			ListView {
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: pickerField.bottom
				anchors.bottom: parent.bottom
				anchors.margins: 8
				clip: true
				spacing: 2
				model: picker.results
				boundsBehavior: Flickable.StopAtBounds
				delegate: Rectangle {
					id: pr
					required property var modelData
					width: ListView.view.width
					height: 44
					radius: Theme.radiusSmall
					color: prArea.containsMouse ? Theme.secondaryContainer : "transparent"
					Image {
						id: prIcon
						width: 28
						height: 28
						anchors.left: parent.left
						anchors.leftMargin: 8
						anchors.verticalCenter: parent.verticalCenter
						sourceSize: Qt.size(56, 56)
						source: Quickshell.iconPath(pr.modelData.icon, "application-x-executable")
					}
					Txt {
						anchors.left: prIcon.right
						anchors.leftMargin: 10
						anchors.right: parent.right
						anchors.rightMargin: 8
						anchors.verticalCenter: parent.verticalCenter
						text: pr.modelData.name
					}
					MouseArea {
						id: prArea
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							Dock.pin(pr.modelData.id);
							win.closeMenu();
						}
					}
				}
			}
		}

		// ---- custom icon editor ----
		Rectangle {
			id: iconPop
			visible: win.menuKind === "icon"
			property bool browsing: false
			width: browsing ? 380 : 360
			height: browsing ? 440 : iconCol.implicitHeight + 24
			radius: Theme.radiusMedium
			color: dropIcon.containsDrag ? Theme.primaryContainer : Theme.surfaceContainerHigh
			border.width: 1
			border.color: Theme.outlineVariant
			x: win.popX(width)
			y: win.popY(height)

			DropArea {
				id: dropIcon
				anchors.fill: parent
				keys: ["text/uri-list"]
				onDropped: d => {
					if (d.urls.length > 0)
						iconField.text = decodeURIComponent(d.urls[0].toString().replace(/^file:\/\//, ""));
				}
			}

			FilePicker {
				visible: iconPop.browsing
				anchors.fill: parent
				anchors.margins: 12
				onPicked: path => {
					iconField.text = path;
					iconPop.browsing = false;
				}
				onCancelled: iconPop.browsing = false
			}

			Column {
				id: iconCol
				visible: !iconPop.browsing
				anchors.fill: parent
				anchors.margins: 12
				spacing: 10

				Txt {
					width: parent.width
					text: win.menuItem ? "Icon for " + win.menuItem.name : ""
					font.weight: Font.Medium
				}
				Field {
					id: iconField
					width: parent.width
					icon: "image"
					placeholder: "Icon name or image path"
					onAccepted: win.applyIcon(text)
				}
				Txt {
					width: parent.width
					wrapMode: Text.Wrap
					font.pixelSize: 12
					color: Theme.surfaceVariantFg
					text: "Type an icon theme name or an image path, browse for a file, or drop one here."
				}
				Row {
					spacing: 8
					Btn {
						icon: "folder"
						label: "Browse…"
						onClicked: iconPop.browsing = true
					}
					Btn {
						label: "Apply"
						variant: 1
						onClicked: win.applyIcon(iconField.text)
					}
					Btn {
						label: "Reset"
						onClicked: win.applyIcon("")
					}
				}
			}
		}
	}
}
