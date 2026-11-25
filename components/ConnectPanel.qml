import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.config
import qs.services
import qs.components

// Wi-Fi / Bluetooth picker opened from the arrow on a Home tile: list, scan, connect.
Rectangle {
	id: root

	// "wifi" | "bluetooth"
	property string kind: "wifi"

	signal closed

	radius: Theme.radiusLarge
	color: Theme.surfaceContainerHigh

	readonly property bool isWifi: kind === "wifi"

	// ---- wifi ----
	readonly property var wifiDevice: {
		const devs = Networking.devices.values;
		for (let i = 0; i < devs.length; i++)
			if (devs[i].type === DeviceType.Wifi)
				return devs[i];
		return null;
	}
	readonly property var networks: {
		if (!wifiDevice)
			return [];
		return wifiDevice.networks.values.slice().sort((a, b) => {
			if (a.connected !== b.connected)
				return a.connected ? -1 : 1;
			if (a.known !== b.known)
				return a.known ? -1 : 1;
			return b.signalStrength - a.signalStrength;
		});
	}
	property string pskFor: ""
	property string failed: ""

	// ---- bluetooth ----
	readonly property var adapter: Bluetooth.defaultAdapter
	readonly property var btDevices: {
		if (!adapter)
			return [];
		return adapter.devices.values.slice().sort((a, b) => {
			if (a.connected !== b.connected)
				return a.connected ? -1 : 1;
			if (a.paired !== b.paired)
				return a.paired ? -1 : 1;
			return a.name.localeCompare(b.name);
		});
	}

	// scan only while the panel is showing
	Binding {
		target: root.wifiDevice
		property: "scannerEnabled"
		value: root.visible && root.isWifi && Networking.wifiEnabled
		when: root.wifiDevice !== null
		restoreMode: Binding.RestoreNone
	}
	Binding {
		target: root.adapter
		property: "discovering"
		value: root.visible && !root.isWifi && root.adapter !== null && root.adapter.enabled
		when: root.adapter !== null
		restoreMode: Binding.RestoreNone
	}
	onVisibleChanged: {
		pskFor = "";
		failed = "";
	}
	onKindChanged: {
		pskFor = "";
		failed = "";
	}

	function bars(s) {
		return s > 0.75 ? "●●●●" : s > 0.5 ? "●●●○" : s > 0.25 ? "●●○○" : "●○○○";
	}

	function secured(n) {
		return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe;
	}

	function pickNetwork(n) {
		failed = "";
		if (n.connected) {
			n.disconnect();
			return;
		}
		if (!n.known && secured(n)) {
			pskFor = pskFor === n.name ? "" : n.name;
			return;
		}
		n.connect();
	}

	function btStatus(d) {
		if (d.pairing)
			return "Pairing…";
		if (d.state === BluetoothDeviceState.Connecting)
			return "Connecting…";
		if (d.state === BluetoothDeviceState.Disconnecting)
			return "Disconnecting…";
		if (d.connected)
			return d.batteryAvailable ? "Connected · " + Math.round(d.battery * 100) + "%" : "Connected";
		return d.paired ? "Paired" : "Available";
	}

	function pickDevice(d) {
		if (d.pairing)
			return;
		if (d.connected)
			d.disconnect();
		else if (d.paired || d.bonded)
			d.connect();
		else
			d.pair();
	}

	MouseArea {
		anchors.fill: parent
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 8
		spacing: 6

		RowLayout {
			Layout.fillWidth: true
			spacing: 6
			Btn {
				icon: "arrow_back"
				variant: 2
				iconSize: 18
				implicitWidth: 34
				implicitHeight: 34
				onClicked: root.closed()
			}
			Txt {
				Layout.fillWidth: true
				text: root.isWifi ? "Wi-Fi" : "Bluetooth"
				font.weight: Font.Bold
			}
			Txt {
				visible: root.isWifi ? Networking.wifiEnabled : (root.adapter !== null && root.adapter.enabled && root.adapter.discovering)
				text: "Scanning…"
				font.pixelSize: 11
				color: Theme.surfaceVariantFg
			}
			Switch {
				checked: Toggles.on(root.kind)
				onToggled: Toggles.toggle(root.kind)
			}
		}

		Txt {
			Layout.fillWidth: true
			Layout.fillHeight: true
			visible: root.isWifi ? (!Networking.wifiEnabled || !root.wifiDevice) : (!root.adapter || !root.adapter.enabled)
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			color: Theme.surfaceVariantFg
			text: root.isWifi ? (Networking.wifiEnabled ? "No Wi-Fi adapter" : "Wi-Fi is off") : (root.adapter ? "Bluetooth is off" : "No Bluetooth adapter")
		}

		ListView {
			Layout.fillWidth: true
			Layout.fillHeight: true
			visible: root.isWifi ? (Networking.wifiEnabled && root.wifiDevice !== null) : (root.adapter !== null && root.adapter.enabled)
			clip: true
			spacing: 2
			boundsBehavior: Flickable.StopAtBounds
			model: root.isWifi ? root.networks : root.btDevices

			delegate: Item {
				id: row
				required property var modelData

				readonly property bool wifi: root.isWifi
				readonly property bool on: modelData.connected
				readonly property bool busy: wifi ? modelData.stateChanging : (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting)
				readonly property bool asking: wifi && root.pskFor === modelData.name

				width: ListView.view.width
				height: asking ? 38 + 44 : 40
				clip: true
				Behavior on height {
					NumberAnimation {
						duration: Theme.durShort
					}
				}

				Rectangle {
					anchors.top: parent.top
					width: parent.width
					height: 38
					radius: Theme.r(19)
					color: row.on ? Theme.primaryContainer : Theme.surfaceFg
					opacity: row.on ? 1 : (area.containsMouse ? 0.1 : 0)
				}

				Row {
					anchors.top: parent.top
					height: 38
					anchors.left: parent.left
					anchors.leftMargin: 12
					anchors.right: parent.right
					anchors.rightMargin: 12
					spacing: 10

					Icon {
						anchors.verticalCenter: parent.verticalCenter
						name: row.wifi ? "wifi" : "bluetooth"
						size: 18
						color: row.on ? Theme.primaryContainerFg : Theme.surfaceFg
						opacity: row.wifi ? 0.4 + 0.6 * row.modelData.signalStrength : 1
					}
					Column {
						anchors.verticalCenter: parent.verticalCenter
						width: parent.width - 28 - (lockIcon.visible ? 28 : 0) - (row.busy ? 28 : 0)
						Txt {
							width: parent.width
							text: row.wifi ? row.modelData.name : row.modelData.name || row.modelData.address
							color: row.on ? Theme.primaryContainerFg : Theme.surfaceFg
							elide: Text.ElideRight
						}
						Txt {
							width: parent.width
							font.pixelSize: 11
							opacity: 0.8
							color: row.on ? Theme.primaryContainerFg : Theme.surfaceVariantFg
							elide: Text.ElideRight
							text: row.wifi ? (row.on ? "Connected" : row.busy ? "Connecting…" : row.modelData.known ? "Saved" : root.secured(row.modelData) ? "Secured" : "Open") : root.btStatus(row.modelData)
						}
					}
					Icon {
						id: lockIcon
						visible: row.wifi && root.secured(row.modelData)
						anchors.verticalCenter: parent.verticalCenter
						name: "lock"
						size: 16
						color: row.on ? Theme.primaryContainerFg : Theme.surfaceVariantFg
					}
					Icon {
						visible: row.busy
						anchors.verticalCenter: parent.verticalCenter
						name: "refresh"
						size: 16
						color: row.on ? Theme.primaryContainerFg : Theme.surfaceVariantFg
						RotationAnimator on rotation {
							running: row.busy
							from: 0
							to: 360
							duration: 900
							loops: Animation.Infinite
						}
					}
				}

				MouseArea {
					id: area
					anchors.top: parent.top
					width: parent.width
					height: 38
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: row.wifi ? root.pickNetwork(row.modelData) : root.pickDevice(row.modelData)
				}

				// password prompt for a new secured network
				Field {
					visible: row.asking
					anchors.bottom: parent.bottom
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.leftMargin: 4
					anchors.rightMargin: 4
					height: 40
					icon: "lock"
					placeholder: root.failed !== "" ? root.failed : "Password"
					input.echoMode: TextInput.Password
					onVisibleChanged: if (visible) {
						text = "";
						input.forceActiveFocus();
					}
					onAccepted: {
						if (text === "")
							return;
						root.failed = "";
						row.modelData.connectWithPsk(text);
						root.pskFor = "";
					}
				}

				Connections {
					target: row.wifi ? row.modelData : null
					ignoreUnknownSignals: true
					function onConnectionFailed(reason) {
						root.failed = "Wrong password";
						root.pskFor = row.modelData.name;
					}
				}
			}
		}
	}
}
