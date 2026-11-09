import QtQuick
import qs.services
import qs.components

Visualizer {
	property var cfg: ({})
	visible: Media.playing
	active: Media.playing
}
