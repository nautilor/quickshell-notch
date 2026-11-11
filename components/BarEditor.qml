import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Edits the items of the full bar: pick an item in a zone, move / remove / configure it, or add new ones.
Item {
	id: root

	implicitHeight: col.implicitHeight

	property string selZone: ""
	property int selIdx: -1

	// ---- drag and drop ----
	property bool dragging: false
	property string dragType: ""
	property string srcZone: ""   // "" = dragged from the palette
	property int srcIdx: -1
	property real ghostX: 0
	property real ghostY: 0
	property string hoverZone: ""
	property int hoverIdx: -1
	property real indX: 0
	property real indY: 0
	property var zoneItems: ({})

	function chipsOf(zone) {
		const out = [];
		for (const c of zoneItems[zone].flowItem.children)
			if (c.chipIndex !== undefined && c.chipIndex >= 0)
				out.push(c);
		out.sort((a, b) => a.chipIndex - b.chipIndex);
		return out;
	}
	function beginDrag(type, zone, idx) {
		dragType = type;
		srcZone = zone;
		srcIdx = idx;
		dragging = true;
	}
	function updateDrag(x, y) {
		ghostX = x;
		ghostY = y;
		let hz = "";
		for (const z of BarLayout.zones) {
			const r = zoneItems[z];
			const q = r.mapFromItem(root, x, y);
			if (q.x >= -8 && q.x <= r.width + 8 && q.y >= -8 && q.y <= r.height + 8) {
				hz = z;
				break;
			}
		}
		hoverZone = hz;
		if (hz === "") {
			hoverIdx = -1;
			return;
		}
		const f = zoneItems[hz].flowItem;
		const q = f.mapFromItem(root, x, y);
		const cs = chipsOf(hz);
		let n = 0;
		for (const c of cs)
			if (c.y + c.height <= q.y || (q.y >= c.y && c.x + c.width / 2 < q.x))
				n++;
		hoverIdx = n;
		let pt;
		if (n < cs.length)
			pt = f.mapToItem(zoneItems[hz], cs[n].x - 4, cs[n].y);
		else if (cs.length > 0)
			pt = f.mapToItem(zoneItems[hz], cs[cs.length - 1].x + cs[cs.length - 1].width + 2, cs[cs.length - 1].y);
		else
			pt = f.mapToItem(zoneItems[hz], 0, 0);
		indX = pt.x;
		indY = pt.y;
	}
	function endDrag() {
		const zone = hoverZone;
		let idx = hoverIdx;
		const sz = srcZone;
		const si = srcIdx;
		const type = dragType;
		dragging = false;
		hoverZone = "";
		hoverIdx = -1;
		if (zone === "")
			return;
		if (sz === "") {
			BarLayout.insertAt(zone, idx, type);
			select(zone, idx);
			return;
		}
		if (sz === zone && si < idx)
			idx--;
		if (sz === zone && si === idx)
			return;
		BarLayout.moveTo(sz, si, zone, idx);
		select(zone, idx);
	}
	function cancelDrag() {
		dragging = false;
		hoverZone = "";
		hoverIdx = -1;
	}

	component Chip: Rectangle {
		id: chip
		property var editor
		property string type
		property bool selected: false
		// "" for chips in the palette
		property string zoneName: ""
		property int chipIndex: -1
		readonly property var def: BarLayout.types[type]
		signal clicked

		implicitHeight: 34
		implicitWidth: chipRow.implicitWidth + 24
		radius: selected ? 12 : 17
		color: selected ? Theme.primary : chipMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
		opacity: editor.dragging && zoneName !== "" && editor.srcZone === zoneName && editor.srcIdx === chipIndex ? 0.3 : 1

		Row {
			id: chipRow
			anchors.centerIn: parent
			spacing: 6
			Icon {
				name: chip.def ? chip.def.icon : "extension"
				size: 18
				fill: chip.selected ? 1 : 0
				color: chip.selected ? Theme.primaryFg : Theme.surfaceVariantFg
				anchors.verticalCenter: parent.verticalCenter
			}
			Txt {
				text: chip.def ? chip.def.title : chip.type
				font.pixelSize: 13
				font.weight: Font.Medium
				elide: Text.ElideNone
				color: chip.selected ? Theme.primaryFg : Theme.surfaceFg
				anchors.verticalCenter: parent.verticalCenter
			}
		}
		MouseArea {
			id: chipMouse
			anchors.fill: parent
			hoverEnabled: true
			preventStealing: true
			cursorShape: chip.editor.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
			property point start
			property bool moved: false
			onPressed: m => {
				start = mapToItem(chip.editor, m.x, m.y);
				moved = false;
			}
			onPositionChanged: m => {
				if (!pressed)
					return;
				const p = mapToItem(chip.editor, m.x, m.y);
				if (!moved && Math.hypot(p.x - start.x, p.y - start.y) > 8) {
					moved = true;
					chip.editor.beginDrag(chip.type, chip.zoneName, chip.chipIndex);
				}
				if (moved)
					chip.editor.updateDrag(p.x, p.y);
			}
			onReleased: {
				if (moved)
					chip.editor.endDrag();
				else
					chip.clicked();
				moved = false;
			}
			onCanceled: {
				if (moved)
					chip.editor.cancelDrag();
				moved = false;
			}
		}
	}

	readonly property var selItem: {
		BarLayout.current;
		return selZone !== "" ? BarLayout.items(selZone)[selIdx] ?? null : null;
	}
	readonly property var selDef: selItem ? BarLayout.types[selItem.type] : null
	readonly property var selCfg: selItem ? BarLayout.resolve(selItem.type, selItem.cfg) : ({})

	function select(zone, i) {
		selZone = zone;
		selIdx = i;
	}

	ColumnLayout {
	id: col
	width: root.width
	spacing: 8

	// ---- zones ----
	Repeater {
		model: BarLayout.zones

		ColumnLayout {
			id: zoneCol
			required property string modelData
			Layout.fillWidth: true
			spacing: 6

			Txt {
				text: BarLayout.zoneNames[zoneCol.modelData]
				font.weight: Font.Medium
				color: Theme.surfaceVariantFg
			}
			Rectangle {
				id: zoneRect
				readonly property alias flowItem: flow
				Layout.fillWidth: true
				implicitHeight: Math.max(50, flow.implicitHeight + 16)
				radius: Theme.radiusMedium
				color: Theme.surfaceContainer
				border.width: root.dragging && root.hoverZone === zoneCol.modelData ? 2 : 0
				border.color: Theme.primary
				Component.onCompleted: root.zoneItems[zoneCol.modelData] = zoneRect

				Txt {
					visible: BarLayout.items(zoneCol.modelData).length === 0
					anchors.centerIn: parent
					text: "empty"
					color: Theme.outline
					font.pixelSize: 12
				}
				Flow {
					id: flow
					anchors.fill: parent
					anchors.margins: 8
					spacing: 6
					Repeater {
						model: BarLayout.items(zoneCol.modelData)
						Chip {
							required property var modelData
							required property int index
							editor: root
							type: modelData.type
							zoneName: zoneCol.modelData
							chipIndex: index
							selected: root.selZone === zoneCol.modelData && root.selIdx === index
							onClicked: root.select(zoneCol.modelData, index)
						}
					}
				}
				Rectangle {
					visible: root.dragging && root.hoverZone === zoneCol.modelData
					x: root.indX
					y: root.indY
					width: 3
					height: 34
					radius: 2
					color: Theme.primary
				}
			}
		}
	}

	// ---- selected item ----
	Rectangle {
		Layout.fillWidth: true
		visible: root.selItem !== null
		implicitHeight: sel.implicitHeight + 24
		radius: Theme.radiusLarge
		color: Theme.surfaceContainerHigh

		ColumnLayout {
			id: sel
			anchors.fill: parent
			anchors.margins: 12
			spacing: 8

			RowLayout {
				Layout.fillWidth: true
				spacing: 6
				Icon {
					name: root.selDef ? root.selDef.icon : ""
					size: 20
					fill: 1
					color: Theme.primary
				}
				Txt {
					Layout.fillWidth: true
					text: root.selDef ? root.selDef.title : ""
					font.weight: Font.Bold
					font.pixelSize: 15
				}
				Btn {
					icon: "arrow_back"
					implicitWidth: 34
					implicitHeight: 34
					iconSize: 18
					enabled: root.selIdx > 0
					onClicked: root.selIdx = BarLayout.move(root.selZone, root.selIdx, -1)
				}
				Btn {
					icon: "arrow_forward"
					implicitWidth: 34
					implicitHeight: 34
					iconSize: 18
					enabled: root.selIdx < BarLayout.items(root.selZone).length - 1
					onClicked: root.selIdx = BarLayout.move(root.selZone, root.selIdx, 1)
				}
				Repeater {
					model: BarLayout.zones.filter(z => z !== root.selZone)
					Btn {
						required property string modelData
						label: "→ " + BarLayout.zoneNames[modelData]
						implicitHeight: 34
						onClicked: {
							const z = modelData;
							root.selIdx = BarLayout.moveToZone(root.selZone, root.selIdx, z);
							root.selZone = z;
						}
					}
				}
				Btn {
					icon: "delete"
					variant: 3
					implicitWidth: 34
					implicitHeight: 34
					iconSize: 18
					onClicked: {
						BarLayout.remove(root.selZone, root.selIdx);
						root.selZone = "";
						root.selIdx = -1;
					}
				}
			}

			Repeater {
				model: root.selDef ? root.selDef.schema : []

				SettingRow {
					id: row
					required property var modelData
					readonly property var field: modelData
					readonly property var current: root.selCfg[field.key]
					title: field.label

					Field {
						visible: row.field.kind === "text"
						implicitWidth: 260
						implicitHeight: 38
						color: Theme.surfaceContainerHighest
						placeholder: row.field.placeholder || ""
						Component.onCompleted: text = row.current ?? ""
						onEdited: v => BarLayout.setConfig(root.selZone, root.selIdx, row.field.key, v)
					}
					Switch {
						visible: row.field.kind === "bool"
						checked: !!row.current
						onToggled: v => BarLayout.setConfig(root.selZone, root.selIdx, row.field.key, v)
					}
					Flow {
						visible: row.field.kind === "choice"
						Layout.maximumWidth: 320
						spacing: 6
						Repeater {
							model: row.field.kind === "choice" ? row.field.options : []
							Btn {
								required property var modelData
								implicitHeight: 34
								label: String(modelData)
								toggleable: true
								toggled: row.current === modelData
								toggledRadius: 14
								onClicked: BarLayout.setConfig(root.selZone, root.selIdx, row.field.key, modelData)
							}
						}
					}
					Flow {
						visible: row.field.kind === "icon"
						Layout.maximumWidth: 320
						spacing: 4
						Repeater {
							model: row.field.kind === "icon" ? WidgetTypes.iconChoices : []
							Btn {
								required property string modelData
								implicitWidth: 36
								implicitHeight: 36
								icon: modelData
								iconSize: 20
								toggleable: true
								toggled: row.current === modelData
								toggledRadius: 12
								onClicked: BarLayout.setConfig(root.selZone, root.selIdx, row.field.key, modelData)
							}
						}
					}
				}
			}
		}
	}

	// ---- palette ----
	Txt {
		text: "Drag items into the bar, or drag items inside it to rearrange"
		font.weight: Font.Medium
		color: Theme.surfaceVariantFg
	}
	Flow {
		Layout.fillWidth: true
		spacing: 6
		Repeater {
			model: BarLayout.order
			Chip {
				required property string modelData
				editor: root
				type: modelData
			}
		}
	}

	Btn {
		icon: "restart_alt"
		label: "Reset to default"
		implicitHeight: 34
		onClicked: {
			BarLayout.reset();
			root.select("", -1);
		}
	}
	}

	// follows the pointer while dragging
	Rectangle {
		visible: root.dragging
		z: 100
		x: root.ghostX - width / 2
		y: root.ghostY - height / 2
		implicitWidth: ghostRow.implicitWidth + 24
		width: implicitWidth
		height: 34
		radius: Theme.r(17)
		color: Theme.primaryContainer
		opacity: 0.92
		Row {
			id: ghostRow
			anchors.centerIn: parent
			spacing: 6
			Icon {
				name: root.dragType !== "" ? BarLayout.types[root.dragType].icon : ""
				size: 18
				fill: 1
				color: Theme.primaryContainerFg
				anchors.verticalCenter: parent.verticalCenter
			}
			Txt {
				text: root.dragType !== "" ? BarLayout.types[root.dragType].title : ""
				font.pixelSize: 13
				font.weight: Font.Medium
				elide: Text.ElideNone
				color: Theme.primaryContainerFg
				anchors.verticalCenter: parent.verticalCenter
			}
		}
	}
}
