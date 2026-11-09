import QtQuick
import qs.config
import qs.services
import qs.components

// Cover art (and optionally the title) of the playing track; click to play/pause.
Item {
	id: root
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("media", cfg)
	readonly property var player: Media.player

	visible: Media.playing || c.alwaysShow
	implicitWidth: row.implicitWidth
	implicitHeight: row.implicitHeight
	width: implicitWidth
	height: implicitHeight

	Row {
		id: row
		spacing: 8

	RoundedImage {
		visible: source != ""
		width: 24
		height: 24
		radius: 8
		anchors.verticalCenter: parent.verticalCenter
		source: root.player ? root.player.trackArtUrl : ""
	}
	Txt {
		visible: root.c.showTitle && root.player !== null
		width: Math.min(implicitWidth, 220)
		text: root.player ? (root.player.trackTitle + (root.player.trackArtist ? " · " + root.player.trackArtist : "")) : ""
		font.pixelSize: 12
		anchors.verticalCenter: parent.verticalCenter
	}
	Icon {
		visible: root.c.alwaysShow && !Media.playing
		name: "music_note"
		size: 18
		color: Theme.surfaceVariantFg
		anchors.verticalCenter: parent.verticalCenter
	}
	}
	MouseArea {
		anchors.fill: parent
		enabled: root.player !== null
		onClicked: root.player.togglePlaying()
	}
}
