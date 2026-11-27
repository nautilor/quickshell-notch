import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.config
import qs.services
import qs.components

// blueman in a window: adapter settings, discoverable, scanning, paired and nearby devices.
Item {
	id: root

	property var adapter: Bluetooth.defaultAdapter
	readonly property bool on: adapter !== null && adapter.enabled
	// seconds the adapter stays discoverable; 0 = until turned off
	readonly property var timeouts: [
		{ label: "Always", value: 0 },
		{ label: "1 min", value: 60 },
		{ label: "3 min", value: 180 },
		{ label: "5 min", value: 300 }
	]

	// ---- device list ----
	property var rows: []
	property string renaming: ""
	property string renameText: ""

	function icon(d) {
		const i = d.icon || "";
		if (/headset|headphone|audio/.test(i))
			return "headphones";
		if (/phone|computer|input|mouse|keyboard/.test(i))
			return "bluetooth";
		return "bluetooth";
	}

	function status(d) {
		if (d.pairing)
			return "Pairing…";
		if (d.state === BluetoothDeviceState.Connecting)
			return "Connecting…";
		if (d.state === BluetoothDeviceState.Disconnecting)
			return "Disconnecting…";
		const parts = [];
		if (d.connected)
			parts.push("Connected");
		else if (d.paired || d.bonded)
			parts.push("Paired");
		else
			parts.push("Available");
		if (d.batteryAvailable)
			parts.push(Math.round(d.battery * 100) + "%");
		if (d.blocked)
			parts.push("Blocked");
		else if (d.trusted)
			parts.push("Trusted");
		return parts.join(" · ");
	}

	function isKnown(d) {
		return d.connected || d.paired || d.bonded;
	}

	function rebuild() {
		const a = root.adapter;
		const next = [];
		if (a && a.enabled) {
			const list = a.devices.values.slice().sort((x, y) => {
				if (x.connected !== y.connected)
					return x.connected ? -1 : 1;
				return (x.name || x.address).localeCompare(y.name || y.address);
			});
			const mine = list.filter(d => root.isKnown(d));
			const nearby = list.filter(d => !root.isKnown(d));
			if (mine.length > 0) {
				next.push({ key: "h:mine", header: "My devices" });
				for (const d of mine)
					next.push({ key: "d:" + d.address, dev: d });
			}
			if (nearby.length > 0) {
				next.push({ key: "h:nearby", header: "Nearby devices" });
				for (const d of nearby)
					next.push({ key: "d:" + d.address, dev: d });
			}
		}
		if (!NetCtl.same(next, root.rows))
			root.rows = next;
	}
	Timer {
		interval: 1200
		repeat: true
		running: root.visible
		triggeredOnStart: true
		onTriggered: if (root.renaming === "")
			root.rebuild()
	}
	// scan while the window is showing
	Binding {
		target: root.adapter
		property: "discovering"
		value: root.visible && root.on
		when: root.adapter !== null
		restoreMode: Binding.RestoreNone
	}

	function pick(d) {
		if (d.pairing)
			return;
		if (d.connected)
			d.disconnect();
		else if (d.paired || d.bonded)
			d.connect();
		else
			d.pair();
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 10

		// ---- adapter ----
		RowLayout {
			Layout.fillWidth: true
			spacing: 16
			SettingRow {
				Layout.preferredWidth: 1
				title: "Bluetooth"
				subtitle: root.adapter ? (root.adapter.enabled ? "On · " + root.adapter.name : root.adapter.state === BluetoothAdapterState.Blocked ? "Blocked (rfkill)" : "Off") : "No adapter"
				Switch {
					checked: root.on
					enabled: root.adapter !== null
					onToggled: v => root.adapter.enabled = v
				}
			}
			SettingRow {
				Layout.preferredWidth: 1
				title: "Make Discoverable"
				subtitle: root.adapter && root.adapter.discoverable ? "Visible to nearby devices" : "Hidden from nearby devices"
				Switch {
					checked: root.adapter ? root.adapter.discoverable : false
					enabled: root.on
					onToggled: v => root.adapter.discoverable = v
				}
			}
		}

		RowLayout {
			Layout.fillWidth: true
			spacing: 16
			SettingRow {
				Layout.preferredWidth: 1
				title: "Pairable"
				subtitle: "Let devices start pairing"
				Switch {
					checked: root.adapter ? root.adapter.pairable : false
					enabled: root.on
					onToggled: v => root.adapter.pairable = v
				}
			}
			SettingRow {
				Layout.preferredWidth: 1
				title: "Search for devices"
				subtitle: root.adapter && root.adapter.discovering ? "Searching…" : "Not searching"
				Switch {
					checked: root.adapter ? root.adapter.discovering : false
					enabled: root.on
					onToggled: v => root.adapter.discovering = v
				}
			}
		}

		// discoverable timeout, adapter picker
		RowLayout {
			Layout.fillWidth: true
			spacing: 8
			visible: root.on
			Txt {
				text: "Discoverable for"
				color: Theme.surfaceVariantFg
			}
			Repeater {
				model: root.timeouts
				Btn {
					required property var modelData
					label: modelData.label
					toggleable: true
					toggled: root.adapter !== null && root.adapter.discoverableTimeout === modelData.value
					implicitHeight: 34
					onClicked: root.adapter.discoverableTimeout = modelData.value
				}
			}
			Item {
				Layout.fillWidth: true
			}
			Repeater {
				model: Bluetooth.adapters.values.length > 1 ? Bluetooth.adapters.values : []
				Btn {
					required property var modelData
					icon: "bluetooth"
					label: modelData.name || modelData.adapterId
					toggleable: true
					toggled: root.adapter === modelData
					implicitHeight: 34
					onClicked: root.adapter = modelData
				}
			}
		}

		// ---- blueman tools ----
		RowLayout {
			Layout.fillWidth: true
			spacing: 8
			Btn {
				icon: "bluetooth_connect"
				label: "Devices"
				iconSize: 18
				implicitHeight: 36
				onClicked: NetCtl.launch(["blueman-manager"])
			}
			Btn {
				icon: "send"
				label: "Send files"
				iconSize: 18
				implicitHeight: 36
				onClicked: NetCtl.launch(["blueman-sendto"])
			}
			Btn {
				icon: "settings"
				label: "Adapters"
				iconSize: 18
				implicitHeight: 36
				onClicked: NetCtl.launch(["blueman-adapters"])
			}
			Btn {
				icon: "tune"
				label: "Local services"
				iconSize: 18
				implicitHeight: 36
				onClicked: NetCtl.launch(["blueman-services"])
			}
		}

		Txt {
			Layout.fillWidth: true
			Layout.fillHeight: true
			visible: !root.on
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			color: Theme.surfaceVariantFg
			text: root.adapter ? "Bluetooth is off" : "No Bluetooth adapter"
		}

		ListView {
			Layout.fillWidth: true
			Layout.fillHeight: true
			visible: root.on
			clip: true
			spacing: 2
			boundsBehavior: Flickable.StopAtBounds
			model: root.rows

			delegate: Item {
				id: item
				required property var modelData

				readonly property bool header: modelData.header !== undefined
				readonly property var dev: modelData.dev ?? null
				readonly property bool editing: dev !== null && root.renaming === dev.address

				width: ListView.view.width
				height: header ? 30 : editing ? 48 + 46 : 48
				clip: true
				Behavior on height {
					NumberAnimation {
						duration: Theme.durShort
					}
				}

				Txt {
					visible: item.header
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 4
					x: 14
					text: item.modelData.header ?? ""
					font.pixelSize: 12
					font.weight: Font.DemiBold
					color: Theme.primary
				}

				NetRow {
					visible: item.dev !== null
					width: parent.width
					icon: item.dev ? root.icon(item.dev) : "bluetooth"
					title: item.dev ? (item.dev.name || item.dev.address) : ""
					subtitle: item.dev ? root.status(item.dev) : ""
					active: item.dev ? item.dev.connected : false
					busy: item.dev ? (item.dev.pairing || item.dev.state === BluetoothDeviceState.Connecting || item.dev.state === BluetoothDeviceState.Disconnecting) : false
					onClicked: root.pick(item.dev)

					Btn {
						visible: item.dev !== null && (item.dev.paired || item.dev.bonded)
						icon: "star"
						variant: 2
						iconSize: 18
						implicitWidth: 34
						implicitHeight: 34
						toggleable: true
						toggled: item.dev ? item.dev.trusted : false
						onClicked: item.dev.trusted = !item.dev.trusted
					}
					Btn {
						icon: "edit"
						variant: 2
						iconSize: 18
						implicitWidth: 34
						implicitHeight: 34
						onClicked: {
							root.renameText = item.dev.name;
							root.renaming = root.renaming === item.dev.address ? "" : item.dev.address;
						}
					}
					Btn {
						icon: "block"
						variant: 2
						iconSize: 18
						implicitWidth: 34
						implicitHeight: 34
						toggleable: true
						toggled: item.dev ? item.dev.blocked : false
						onClicked: item.dev.blocked = !item.dev.blocked
					}
					Btn {
						visible: item.dev !== null && (item.dev.paired || item.dev.bonded)
						icon: "delete"
						variant: 2
						iconSize: 18
						implicitWidth: 34
						implicitHeight: 34
						onClicked: item.dev.forget()
					}
				}

				Field {
					visible: item.editing
					anchors.bottom: parent.bottom
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.leftMargin: 4
					anchors.rightMargin: 4
					height: 40
					icon: "edit"
					placeholder: "Device name"
					text: root.renameText
					onEdited: v => root.renameText = v
					onVisibleChanged: if (visible)
						input.forceActiveFocus()
					onAccepted: {
						item.dev.name = text;
						root.renaming = "";
					}
				}
			}
		}
	}
}
