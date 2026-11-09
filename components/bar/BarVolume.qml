import QtQuick
import qs.config
import qs.services
import qs.components

// Volume icon (+ percentage); click mutes, scroll changes the volume.
BarButton {
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("volume", cfg)
	icon: Audio.icon()
	label: c.showPercent ? Math.round(Audio.volume * 100) + "%" : ""
	onClicked: Audio.toggleMute()
	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.NoButton
		onWheel: w => Audio.step(w.angleDelta.y > 0 ? 0.05 : -0.05)
	}
}
