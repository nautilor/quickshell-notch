import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config
import qs.services
import qs.components

// nm-applet in a window: networks, VPN, saved connections, connection info, hidden networks, hotspot.
Item {
	id: root

	property string sub: "networks"
	readonly property var tabs: [
		{ id: "networks", label: "Networks", icon: "wifi" },
		{ id: "vpn", label: "VPN", icon: "vpn" },
		{ id: "saved", label: "Saved", icon: "bookmark" },
		{ id: "info", label: "Info", icon: "info" },
		{ id: "hidden", label: "Hidden", icon: "visibility_off" },
		{ id: "hotspot", label: "Hotspot", icon: "access_point" }
	]

	function secured(n) {
		return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe;
	}

	// ---- networks list ----
	property var rows: []
	property string pskFor: ""
	property string psk: ""
	property string failed: ""

	function rebuild() {
		const next = [];
		const wired = NetCtl.wiredDevices;
		if (wired.length > 0) {
			next.push({ key: "h:wired", header: "Ethernet" });
			for (const d of wired)
				next.push({ key: "w:" + d.name, wired: d });
		}
		const dev = NetCtl.wifiDevice;
		if (dev && Networking.wifiEnabled) {
			next.push({ key: "h:wifi", header: "Wi-Fi networks" });
			const list = dev.networks.values.slice().sort((a, b) => {
				if (a.connected !== b.connected)
					return a.connected ? -1 : 1;
				if (a.known !== b.known)
					return a.known ? -1 : 1;
				return b.signalStrength - a.signalStrength;
			});
			for (const n of list)
				next.push({ key: "n:" + n.name, net: n });
		}
		if (!NetCtl.same(next, root.rows))
			root.rows = next;
	}
	Timer {
		interval: 1500
		repeat: true
		running: root.visible && root.sub === "networks"
		triggeredOnStart: true
		onTriggered: if (root.pskFor === "")
			root.rebuild()
	}
	Binding {
		target: NetCtl.wifiDevice
		property: "scannerEnabled"
		value: root.visible && root.sub === "networks" && Networking.wifiEnabled
		when: NetCtl.wifiDevice !== null
		restoreMode: Binding.RestoreNone
	}

	function pick(n) {
		failed = "";
		if (n.connected) {
			n.disconnect();
			return;
		}
		if (!n.known && secured(n)) {
			psk = "";
			pskFor = pskFor === n.name ? "" : n.name;
			return;
		}
		n.connect();
	}

	readonly property string connectivityText: {
		if (!NetCtl.networking)
			return "Networking is off";
		switch (Networking.connectivity) {
		case NetworkConnectivity.Full:
			return "Connected to the internet";
		case NetworkConnectivity.Limited:
			return "Limited connectivity";
		case NetworkConnectivity.Portal:
			return "Sign-in required (captive portal)";
		case NetworkConnectivity.None:
			return "No connectivity";
		default:
			return "Connectivity unknown";
		}
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 10

		// ---- switches ----
		RowLayout {
			Layout.fillWidth: true
			spacing: 16
			SettingRow {
				Layout.preferredWidth: 1
				title: "Enable Networking"
				subtitle: root.connectivityText
				Switch {
					checked: NetCtl.networking
					onToggled: v => NetCtl.setNetworking(v)
				}
			}
			SettingRow {
				Layout.preferredWidth: 1
				title: "Enable Wi-Fi"
				subtitle: Networking.wifiHardwareEnabled ? (NetCtl.wifiDevice ? NetCtl.wifiDevice.name : "No Wi-Fi adapter") : "Switched off by hardware"
				Switch {
					checked: Networking.wifiEnabled
					enabled: Networking.wifiHardwareEnabled
					onToggled: v => Networking.wifiEnabled = v
				}
			}
			Btn {
				icon: "edit"
				label: "Edit connections"
				implicitHeight: 40
				onClicked: NetCtl.editConnections()
			}
		}

		// ---- sub tabs ----
		Flow {
			Layout.fillWidth: true
			spacing: 8
			Repeater {
				model: root.tabs
				Btn {
					required property var modelData
					icon: modelData.icon
					label: modelData.label
					iconSize: 18
					implicitHeight: 38
					toggleable: true
					toggled: root.sub === modelData.id
					onClicked: root.sub = modelData.id
				}
			}
		}

		StackLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			currentIndex: root.tabs.findIndex(t => t.id === root.sub)

			// ---- Networks ----
			Item {
				Txt {
					anchors.centerIn: parent
					visible: !NetCtl.networking || (!NetCtl.wifiDevice && NetCtl.wiredDevices.length === 0) || (!Networking.wifiEnabled && NetCtl.wiredDevices.length === 0)
					color: Theme.surfaceVariantFg
					text: !NetCtl.networking ? "Networking is off" : !NetCtl.wifiDevice ? "No network adapter" : "Wi-Fi is off"
				}
				ListView {
					anchors.fill: parent
					clip: true
					spacing: 2
					boundsBehavior: Flickable.StopAtBounds
					model: root.rows

					delegate: Item {
						id: item
						required property var modelData

						readonly property bool header: modelData.header !== undefined
						readonly property var net: modelData.net ?? null
						readonly property var dev: modelData.wired ?? null
						readonly property bool asking: net !== null && root.pskFor === net.name

						width: ListView.view.width
						height: header ? 30 : asking ? 48 + 46 : 48
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

						// Wi-Fi network
						NetRow {
							visible: item.net !== null
							width: parent.width
							icon: "wifi"
							iconOpacity: item.net ? 0.4 + 0.6 * item.net.signalStrength : 1
							title: item.net ? item.net.name : ""
							subtitle: !item.net ? "" : item.net.connected ? "Connected" : item.net.stateChanging ? "Connecting…" : item.net.known ? "Saved" : root.secured(item.net) ? "Secured" : "Open"
							active: item.net ? item.net.connected : false
							busy: item.net ? item.net.stateChanging : false
							onClicked: root.pick(item.net)

							Icon {
								visible: item.net !== null && root.secured(item.net)
								name: "lock"
								size: 16
								color: item.net && item.net.connected ? Theme.primaryContainerFg : Theme.surfaceVariantFg
							}
							Btn {
								visible: item.net !== null && item.net.known
								icon: "delete"
								variant: 2
								iconSize: 18
								implicitWidth: 34
								implicitHeight: 34
								onClicked: item.net.forget()
							}
						}

						// Ethernet
						NetRow {
							visible: item.dev !== null
							width: parent.width
							icon: "lan"
							title: item.dev ? item.dev.name : ""
							subtitle: !item.dev ? "" : item.dev.connected ? "Connected" : item.dev.hasLink ? "Disconnected" : "Cable unplugged"
							active: item.dev ? item.dev.connected : false
							onClicked: {
								if (item.dev.connected)
									item.dev.disconnect();
								else
									NetCtl.nm(["device", "connect", item.dev.name]);
							}
						}

						// password prompt for a new secured network
						Field {
							visible: item.asking
							anchors.bottom: parent.bottom
							anchors.left: parent.left
							anchors.right: parent.right
							anchors.leftMargin: 4
							anchors.rightMargin: 4
							height: 40
							icon: "lock"
							placeholder: root.failed !== "" ? root.failed : "Password"
							input.echoMode: TextInput.Password
							text: root.psk
							onEdited: v => root.psk = v
							onVisibleChanged: if (visible)
								input.forceActiveFocus()
							onAccepted: {
								if (text === "")
									return;
								root.failed = "";
								item.net.connectWithPsk(text);
								root.pskFor = "";
							}
						}
						Connections {
							target: item.net
							ignoreUnknownSignals: true
							function onConnectionFailed(reason) {
								root.failed = "Could not connect, check the password";
								root.psk = "";
								root.pskFor = item.net.name;
							}
						}
					}
				}
			}

			// ---- VPN ----
			Item {
				ColumnLayout {
					anchors.fill: parent
					spacing: 6
					Txt {
						Layout.fillWidth: true
						Layout.fillHeight: true
						visible: NetCtl.vpns.length === 0
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						color: Theme.surfaceVariantFg
						text: "No VPN connections yet"
					}
					ListView {
						Layout.fillWidth: true
						Layout.fillHeight: true
						visible: NetCtl.vpns.length > 0
						clip: true
						spacing: 2
						boundsBehavior: Flickable.StopAtBounds
						model: NetCtl.vpns
						delegate: NetRow {
							required property var modelData
							width: ListView.view.width
							icon: "vpn"
							title: modelData.name
							subtitle: modelData.active ? "Connected" : modelData.type === "wireguard" ? "WireGuard" : "VPN"
							active: modelData.active
							onClicked: modelData.active ? NetCtl.connectionDown(modelData.uuid) : NetCtl.connectionUp(modelData.uuid)
						}
					}
					Btn {
						icon: "add"
						label: "Add a VPN connection"
						implicitHeight: 40
						onClicked: NetCtl.editConnections()
					}
				}
			}

			// ---- Saved connections ----
			Item {
				ListView {
					anchors.fill: parent
					clip: true
					spacing: 2
					boundsBehavior: Flickable.StopAtBounds
					model: NetCtl.saved
					delegate: NetRow {
						required property var modelData
						width: ListView.view.width
						icon: modelData.type === "802-3-ethernet" ? "lan" : "wifi"
						title: modelData.name
						subtitle: modelData.active ? "Active" : modelData.type === "802-3-ethernet" ? "Ethernet" : "Wi-Fi"
						active: modelData.active
						onClicked: modelData.active ? NetCtl.connectionDown(modelData.uuid) : NetCtl.connectionUp(modelData.uuid)

						Txt {
							text: "Auto"
							font.pixelSize: 12
							color: modelData.active ? Theme.primaryContainerFg : Theme.surfaceVariantFg
						}
						Switch {
							checked: modelData.autoconnect
							onToggled: v => NetCtl.setAutoconnect(modelData.uuid, v)
						}
						Btn {
							icon: "delete"
							variant: 2
							iconSize: 18
							implicitWidth: 34
							implicitHeight: 34
							onClicked: NetCtl.connectionDelete(modelData.uuid)
						}
					}
				}
			}

			// ---- Connection info ----
			Item {
				Flickable {
					anchors.fill: parent
					clip: true
					contentHeight: infoCol.implicitHeight
					boundsBehavior: Flickable.StopAtBounds

					ColumnLayout {
						id: infoCol
						width: parent.width
						spacing: 10

						Txt {
							visible: NetCtl.info.length === 0
							Layout.fillWidth: true
							horizontalAlignment: Text.AlignHCenter
							color: Theme.surfaceVariantFg
							text: "No network devices"
						}

						Repeater {
							model: NetCtl.info
							Rectangle {
								id: card
								required property var modelData
								readonly property var lines: [
									["Connection", modelData.connection],
									["State", modelData.state],
									["Network", modelData.ssid ?? ""],
									["Signal", modelData.signal ? modelData.signal + "%" : ""],
									["Speed", modelData.rate ?? ""],
									["Channel", modelData.channel ?? ""],
									["Security", modelData.security ?? ""],
									["Hardware address", modelData.hwaddr],
									["IPv4 address", modelData.ip4.join(", ")],
									["Gateway", modelData.gateway],
									["DNS", modelData.dns.join(", ")],
									["IPv6 address", modelData.ip6.join(", ")],
									["MTU", modelData.mtu]
								].filter(l => l[1] !== "")
								Layout.fillWidth: true
								implicitHeight: cardCol.implicitHeight + 24
								radius: Theme.r(18)
								color: Theme.surfaceContainerHigh

								ColumnLayout {
									id: cardCol
									anchors.fill: parent
									anchors.margins: 12
									spacing: 2
									Txt {
										text: card.modelData.device + "  ·  " + card.modelData.type
										font.weight: Font.Bold
										color: Theme.primary
									}
									Repeater {
										model: card.lines
										RowLayout {
											required property var modelData
											Layout.fillWidth: true
											Txt {
												Layout.preferredWidth: 150
												text: modelData[0]
												color: Theme.surfaceVariantFg
												font.pixelSize: 13
											}
											Txt {
												Layout.fillWidth: true
												text: modelData[1]
												font.pixelSize: 13
												elide: Text.ElideRight
											}
										}
									}
								}
							}
						}
					}
				}
			}

			// ---- Hidden network ----
			Item {
				id: hidden
				property bool wpa: true
				property string result: ""
				property bool busy: false

				ColumnLayout {
					anchors.top: parent.top
					width: Math.min(parent.width, 460)
					spacing: 10

					Txt {
						Layout.fillWidth: true
						wrapMode: Text.WordWrap
						color: Theme.surfaceVariantFg
						text: "Connect to a network that does not broadcast its name."
					}
					Field {
						id: hiddenSsid
						Layout.fillWidth: true
						icon: "wifi"
						placeholder: "Network name (SSID)"
					}
					RowLayout {
						spacing: 8
						Btn {
							label: "WPA / WPA2 / WPA3"
							toggleable: true
							toggled: hidden.wpa
							implicitHeight: 38
							onClicked: hidden.wpa = true
						}
						Btn {
							label: "None"
							toggleable: true
							toggled: !hidden.wpa
							implicitHeight: 38
							onClicked: hidden.wpa = false
						}
					}
					Field {
						id: hiddenPsk
						Layout.fillWidth: true
						visible: hidden.wpa
						icon: "lock"
						placeholder: "Password"
						input.echoMode: TextInput.Password
					}
					RowLayout {
						spacing: 12
						Btn {
							variant: 1
							icon: "link"
							label: "Connect"
							busy: hidden.busy
							implicitHeight: 42
							onClicked: {
								if (hiddenSsid.text === "" || hidden.busy)
									return;
								hidden.busy = true;
								hidden.result = "Connecting…";
								NetCtl.connectHidden(hiddenSsid.text, hidden.wpa ? hiddenPsk.text : "", (ok, out) => {
									hidden.busy = false;
									hidden.result = ok ? "Connected" : out;
									if (ok)
										hiddenPsk.text = "";
								});
							}
						}
						Txt {
							Layout.fillWidth: true
							text: hidden.result
							wrapMode: Text.WordWrap
							maximumLineCount: 2
							color: hidden.result === "Connected" ? Theme.primary : Theme.surfaceVariantFg
						}
					}
				}
			}

			// ---- Hotspot ----
			Item {
				id: hotspot
				property string result: ""
				property bool busy: false

				ColumnLayout {
					anchors.top: parent.top
					width: Math.min(parent.width, 460)
					spacing: 10

					Txt {
						Layout.fillWidth: true
						wrapMode: Text.WordWrap
						color: Theme.surfaceVariantFg
						text: NetCtl.hotspotActive ? "Hotspot is on. Other devices can join it." : "Share this computer's connection. The Wi-Fi adapter leaves its current network while the hotspot is on."
					}
					Field {
						id: hotspotSsid
						Layout.fillWidth: true
						icon: "access_point"
						placeholder: "Network name (SSID)"
						text: "Hotspot"
					}
					Field {
						id: hotspotPsk
						Layout.fillWidth: true
						icon: "lock"
						placeholder: "Password (8 characters or more)"
						input.echoMode: TextInput.Password
					}
					RowLayout {
						spacing: 12
						Btn {
							variant: 1
							icon: "access_point"
							label: NetCtl.hotspotActive ? "Turn off" : "Create network"
							implicitHeight: 42
							onClicked: {
								if (hotspot.busy)
									return;
								if (NetCtl.hotspotActive) {
									hotspot.busy = true;
									NetCtl.stopHotspot((ok, out) => {
										hotspot.busy = false;
										hotspot.result = ok ? "" : out;
									});
									return;
								}
								if (hotspotSsid.text === "" || hotspotPsk.text.length < 8) {
									hotspot.result = "Enter a name and a password of 8 characters or more";
									return;
								}
								hotspot.busy = true;
								hotspot.result = "Creating…";
								NetCtl.startHotspot(hotspotSsid.text, hotspotPsk.text, (ok, out) => {
									hotspot.busy = false;
									hotspot.result = ok ? "" : out;
								});
							}
						}
						Txt {
							Layout.fillWidth: true
							text: hotspot.result
							wrapMode: Text.WordWrap
							maximumLineCount: 2
							color: Theme.surfaceVariantFg
						}
					}
				}
			}
		}
	}
}
