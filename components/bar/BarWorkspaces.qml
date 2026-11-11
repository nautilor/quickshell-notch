import QtQuick
import qs.config
import qs.components

// All workspaces as pills inside a tonal capsule.
BarCapsule {
	property var cfg: ({})
	padding: 5
	fill: Theme.surfaceContainer

	WorkspaceRow {
		anchors.verticalCenter: parent.verticalCenter
		pillHeight: 22
	}
}
