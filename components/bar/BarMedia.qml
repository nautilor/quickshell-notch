import QtQuick
import qs.config
import qs.services
import qs.components

// Cover art (and optionally the title) of the playing track, with previous / play-pause / next.
// Clicking the art or title also toggles play/pause.
BarCapsule {
	id: root
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("media", cfg)
	readonly property var player: Media.player

	component Ctl: Rectangle {
		id: ctl
		property string icon
		property bool primary: false
		property bool enabled: true
		signal clicked
		width: primary ? 28 : 24
		height: width
		radius: ctlMouse.pressed ? Theme.r(6) : Theme.pillRadius(width)
		color: primary ? Theme.primary : ctlMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"
		opacity: enabled ? 1 : 0.4
		Behavior on radius {
			SpringAnimation {
				spring: Theme.springBouncy
				damping: Theme.dampBouncy
				epsilon: 0.25
			}
		}
		Icon {
			anchors.centerIn: parent
			name: ctl.icon
			size: ctl.primary ? 18 : 16
			fill: 1
			color: ctl.primary ? Theme.primaryFg : Theme.surfaceVariantFg
		}
		MouseArea {
			id: ctlMouse
			anchors.fill: parent
			hoverEnabled: true
			enabled: ctl.enabled
			cursorShape: Qt.PointingHandCursor
			onClicked: ctl.clicked()
		}
	}

	visible: Media.playing || c.alwaysShow
	padding: 4
	hoverable: true
	hovered: infoMouse.containsMouse

	Row {
		id: row
		spacing: 6
		anchors.verticalCenter: parent.verticalCenter

		Item {
			width: info.width
			height: info.height
			anchors.verticalCenter: parent.verticalCenter

			Row {
				id: info
				spacing: 8
				anchors.verticalCenter: parent.verticalCenter

				RoundedImage {
					visible: source != ""
					width: 24
					height: 24
					radius: Media.playing ? 12 : 8
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
				id: infoMouse
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				enabled: root.player !== null
				onClicked: root.player.togglePlaying()
			}
		}

		Row {
			visible: root.c.showControls && root.player !== null
			spacing: 2
			anchors.verticalCenter: parent.verticalCenter
			Ctl {
				icon: "skip_previous"
				enabled: root.player && root.player.canGoPrevious
				anchors.verticalCenter: parent.verticalCenter
				onClicked: root.player.previous()
			}
			Ctl {
				icon: Media.playing ? "pause" : "play_arrow"
				primary: true
				enabled: root.player && root.player.canTogglePlaying
				anchors.verticalCenter: parent.verticalCenter
				onClicked: root.player.togglePlaying()
			}
			Ctl {
				icon: "skip_next"
				enabled: root.player && root.player.canGoNext
				anchors.verticalCenter: parent.verticalCenter
				onClicked: root.player.next()
			}
		}
	}
}
