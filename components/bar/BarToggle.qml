import QtQuick
import qs.services
import qs.components

// Wi-Fi, Bluetooth, caffeine, microphone or do-not-disturb.
BarButton {
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("toggle", cfg)
	icon: Toggles.icon(c.kind)
	active: Toggles.on(c.kind)
	onClicked: Toggles.toggle(c.kind)
}
