import QtQuick
import qs.config
import qs.services
import qs.components

// Compact now-playing tile for the dock: art, title/artist and transport buttons.
Rectangle {
	id: root

	property var cfg: ({})
	property bool editing: false
	readonly property var player: Media.player

	radius: Math.min(width, height) * 0.28
	color: Theme.secondaryContainer
	clip: true

	// blurred-ish backdrop: the album art, dimmed
	RoundedImage {
		anchors.fill: parent
		radius: root.radius
		source: root.player ? root.player.trackArtUrl : ""
		visible: status === Image.Ready
		opacity: 0.35
	}

	Item {
		id: art
		anchors.left: parent.left
		anchors.leftMargin: 6
		anchors.verticalCenter: parent.verticalCenter
		width: root.height - 12
		height: width
		Rectangle {
			anchors.fill: parent
			radius: root.radius * 0.6
			color: Theme.secondaryContainer
			Icon {
				anchors.centerIn: parent
				name: root.player ? "music_note" : "music_off"
				size: parent.width * 0.5
				color: Theme.secondaryContainerFg
			}
		}
		RoundedImage {
			anchors.fill: parent
			radius: root.radius * 0.6
			source: root.player ? root.player.trackArtUrl : ""
			visible: status === Image.Ready
		}
	}

	// transport buttons, right-aligned and vertically centred
	Row {
		id: controls
		visible: root.player !== null
		anchors.right: parent.right
		anchors.rightMargin: 8
		anchors.verticalCenter: parent.verticalCenter
		spacing: 2
		Repeater {
			model: [
				{ icon: "skip_previous", act: 0 },
				{ icon: Media.playing ? "pause" : "play_arrow", act: 1 },
				{ icon: "skip_next", act: 2 }
			]
			Item {
				id: b
				required property var modelData
				width: 24
				height: 24
				Icon {
					anchors.centerIn: parent
					name: b.modelData.icon
					size: 20
					fill: 1
					color: Theme.secondaryContainerFg
					opacity: ba.containsMouse ? 1 : 0.85
				}
				MouseArea {
					id: ba
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						if (!root.player)
							return;
						if (b.modelData.act === 0)
							root.player.previous();
						else if (b.modelData.act === 1)
							root.player.togglePlaying();
						else
							root.player.next();
					}
				}
			}
		}
	}

	Column {
		anchors.left: art.right
		anchors.leftMargin: 10
		anchors.right: controls.visible ? controls.left : parent.right
		anchors.rightMargin: 8
		anchors.verticalCenter: parent.verticalCenter
		spacing: 1

		Txt {
			width: parent.width
			text: root.player ? (root.player.trackTitle || "Unknown") : "Nothing playing"
			font.pixelSize: 13
			font.weight: Font.Bold
			elide: Text.ElideRight
			color: Theme.secondaryContainerFg
		}
		Txt {
			visible: root.player !== null && (root.player.trackArtist || "") !== ""
			width: parent.width
			text: root.player ? root.player.trackArtist : ""
			font.pixelSize: 11
			elide: Text.ElideRight
			color: Theme.secondaryContainerFg
			opacity: 0.75
		}
	}
}
