import QtQuick
import qs.config
import qs.services
import qs.components

// Recording, caffeine, muted microphone and do-not-disturb indicators.
Row {
	property var cfg: ({})
	spacing: 8

	Icon {
		visible: Recorder.recording
		name: "fiber_manual_record"
		size: 18
		fill: 1
		color: Theme.error
		anchors.verticalCenter: parent.verticalCenter
	}
	Icon {
		visible: Caffeine.active
		name: "coffee"
		size: 18
		fill: 1
		color: Theme.tertiary
		anchors.verticalCenter: parent.verticalCenter
	}
	Icon {
		visible: Mic.muted
		name: "mic_off"
		size: 18
		fill: 1
		color: Theme.error
		anchors.verticalCenter: parent.verticalCenter
	}
	Icon {
		visible: Settings.dnd
		name: "notifications_off"
		size: 18
		fill: 1
		color: Theme.surfaceVariantFg
		anchors.verticalCenter: parent.verticalCenter
	}
}
