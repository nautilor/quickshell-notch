import QtQuick
import qs.services
import qs.components

// Opens one of the notch tabs (application launcher, clipboard, ...).
BarButton {
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("shortcut", cfg)
	icon: c.icon
	label: c.label
	onClicked: NotchCtl.toggle(c.tab)
}
