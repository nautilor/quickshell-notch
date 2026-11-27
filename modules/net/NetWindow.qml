import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components
import qs.components.net

// Centered Wi-Fi / Bluetooth settings, on a dimmed overlay. Click outside or press Escape to close.
PanelWindow {
	id: win

	required property var modelData
	screen: modelData

	readonly property bool shown: NetCtl.open && (NetCtl.screen === "" || NetCtl.screen === modelData.name)

	visible: shown || card.opacity > 0.01
	anchors.top: true
	anchors.bottom: true
	anchors.left: true
	anchors.right: true
	color: "transparent"
	exclusionMode: ExclusionMode.Ignore

	WlrLayershell.namespace: "notch-net"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

	Shortcut {
		sequence: "Escape"
		enabled: win.shown
		onActivated: NetCtl.close()
	}

	Rectangle {
		anchors.fill: parent
		color: "#000000"
		opacity: win.shown ? 0.45 : 0
		Behavior on opacity {
			NumberAnimation {
				duration: Theme.durMedium
			}
		}
		MouseArea {
			anchors.fill: parent
			onClicked: NetCtl.close()
		}
	}

	Rectangle {
		id: card
		anchors.centerIn: parent
		width: Math.min(parent.width - 48, 880)
		height: Math.min(parent.height - 48, 640)
		radius: Theme.radiusXLarge
		color: Theme.notchSolid
		border.width: 1
		border.color: Theme.outlineVariant
		opacity: win.shown ? 1 : 0
		scale: win.shown ? 1 : 0.94
		Behavior on opacity {
			NumberAnimation {
				duration: Theme.durMedium
			}
		}
		Behavior on scale {
			NumberAnimation {
				duration: Theme.durMedium
				easing.type: Easing.BezierSpline
				easing.bezierCurve: Theme.emphasizedDecel
			}
		}

		// swallow clicks so they do not reach the backdrop
		MouseArea {
			anchors.fill: parent
		}

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 20
			spacing: 12

			RowLayout {
				Layout.fillWidth: true
				spacing: 8
				Btn {
					icon: "wifi"
					label: "Wi-Fi"
					toggleable: true
					toggled: NetCtl.page === "wifi"
					implicitHeight: 42
					onClicked: NetCtl.page = "wifi"
				}
				Btn {
					icon: "bluetooth"
					label: "Bluetooth"
					toggleable: true
					toggled: NetCtl.page === "bluetooth"
					implicitHeight: 42
					onClicked: NetCtl.page = "bluetooth"
				}
				Item {
					Layout.fillWidth: true
				}
				Btn {
					icon: "close"
					variant: 2
					implicitWidth: 42
					implicitHeight: 42
					onClicked: NetCtl.close()
				}
			}

			Loader {
				Layout.fillWidth: true
				Layout.fillHeight: true
				active: win.shown
				sourceComponent: NetCtl.page === "bluetooth" ? bluetooth : wifi
			}
		}
	}

	Component {
		id: wifi
		WifiPage {}
	}
	Component {
		id: bluetooth
		BluetoothPage {}
	}
}
