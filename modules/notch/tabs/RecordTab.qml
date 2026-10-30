import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

// Screen recorder: pick what to capture (screens, a window or a region), then record.
Item {
	id: root

	readonly property var modes: [
		{ id: "screens", icon: "monitor", title: "Screens", sub: "One or more" },
		{ id: "window", icon: "web_asset", title: "Window", sub: "A visible window" }
	]

	function clock(s) {
		const p = n => (n < 10 ? "0" : "") + n;
		return p(Math.floor(s / 60)) + ":" + p(s % 60);
	}

	function startRecording() {
		if (!Recorder.canStart)
			return;
		NotchCtl.close();
		Recorder.start();
	}

	Component.onCompleted: {
		if (Recorder.selectedScreens.length === 0 && Hyprland.focusedMonitor)
			Recorder.selectedScreens = [Hyprland.focusedMonitor.name];
		Recorder.refreshWindows();
	}

	RowLayout {
		anchors.fill: parent
		spacing: 12

		// what to record
		ColumnLayout {
			Layout.fillHeight: true
			Layout.preferredWidth: 200
			spacing: 8

			Repeater {
				model: root.modes

				QuickTile {
					required property var modelData
					Layout.fillWidth: true
					Layout.fillHeight: true
					enabled: !Recorder.recording
					icon: modelData.icon
					title: modelData.title
					subtitle: modelData.sub
					toggled: Recorder.mode === modelData.id
					onClicked: {
						Recorder.mode = modelData.id;
						if (modelData.id === "window")
							Recorder.refreshWindows();
					}
				}
			}
		}

		// target + controls
		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			spacing: 8

			// recording in progress
			Item {
				visible: Recorder.recording
				Layout.fillWidth: true
				Layout.fillHeight: true

				Column {
					anchors.centerIn: parent
					spacing: 6
					Txt {
						anchors.horizontalCenter: parent.horizontalCenter
						text: root.clock(Recorder.elapsed)
						opacity: Recorder.merging ? 0.4 : 1
						font.pixelSize: 40
						font.weight: Font.Bold
						color: Theme.error
					}
					Txt {
						anchors.horizontalCenter: parent.horizontalCenter
						text: Recorder.merging ? "Merging screens…" : Recorder.dir
						color: Theme.surfaceVariantFg
						font.pixelSize: 12
					}
				}
			}

			// screens
			Flow {
				visible: !Recorder.recording && Recorder.mode === "screens"
				Layout.fillWidth: true
				Layout.fillHeight: true
				spacing: 8

				Repeater {
					model: Quickshell.screens

					QuickTile {
						required property var modelData
						width: Math.max(150, (parent.width - 8) / 2)
						height: 64
						icon: "monitor"
						title: modelData.name
						subtitle: modelData.width + "×" + modelData.height
						toggled: Recorder.isSelected(modelData.name)
						onClicked: Recorder.toggleScreen(modelData.name)
					}
				}
				QuickTile {
					visible: Quickshell.screens.length > 1
					width: Math.max(150, (parent.width - 8) / 2)
					height: 64
					icon: "monitor_multiple"
					title: "All screens"
					subtitle: "Separate file each"
					toggled: Recorder.selectedScreens.length === Quickshell.screens.length
					onClicked: Recorder.selectAll()
				}
			}

			// windows
			ListView {
				visible: !Recorder.recording && Recorder.mode === "window"
				Layout.fillWidth: true
				Layout.fillHeight: true
				clip: true
				spacing: 4
				model: Recorder.windows

				delegate: Rectangle {
					id: row
					required property var modelData
					readonly property bool picked: Recorder.chosenWindow !== null && Recorder.chosenWindow.geometry === modelData.geometry
					width: ListView.view.width
					height: 44
					radius: picked ? 14 : 22
					color: picked ? Theme.primaryContainer : Theme.surfaceContainerHigh
					Behavior on color {
						ColorAnimation {
							duration: Theme.durShort
						}
					}

					Column {
						anchors.left: parent.left
						anchors.right: parent.right
						anchors.leftMargin: 16
						anchors.rightMargin: 16
						anchors.verticalCenter: parent.verticalCenter
						Txt {
							width: parent.width
							text: row.modelData.title || row.modelData.cls
							font.weight: Font.Medium
							color: row.picked ? Theme.primaryContainerFg : Theme.surfaceFg
						}
						Txt {
							width: parent.width
							text: row.modelData.cls + " · " + row.modelData.screen
							font.pixelSize: 11
							color: row.picked ? Theme.primaryContainerFg : Theme.surfaceVariantFg
						}
					}
					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: Recorder.chosenWindow = row.modelData
					}
				}

				Txt {
					visible: parent.count === 0
					anchors.centerIn: parent
					text: "No windows found"
					color: Theme.surfaceVariantFg
				}
			}

			RowLayout {
				Layout.fillWidth: true
				spacing: 8

				Btn {
					icon: Recorder.micAudio ? "mic" : "mic_off"
					label: "Mic"
					toggleable: true
					toggled: Recorder.micAudio
					enabled: !Recorder.recording
					Layout.preferredHeight: 48
					onClicked: Recorder.micAudio = !Recorder.micAudio
				}
				Btn {
					icon: Recorder.systemAudio ? "volume_up" : "volume_off"
					label: "System"
					toggleable: true
					toggled: Recorder.systemAudio
					enabled: !Recorder.recording
					Layout.preferredHeight: 48
					onClicked: Recorder.systemAudio = !Recorder.systemAudio
				}
				Btn {
					Layout.fillWidth: true
					Layout.preferredHeight: 48
					icon: Recorder.recording ? "stop" : "fiber_manual_record"
					label: Recorder.recording ? "Stop" : "Record"
					variant: Recorder.recording ? 3 : 1
					opacity: Recorder.recording ? (Recorder.merging ? 0.4 : 1) : Recorder.canStart ? 1 : 0.4
					onClicked: Recorder.recording ? Recorder.stop() : root.startRecording()
				}
			}
		}
	}
}
