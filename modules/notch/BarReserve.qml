import Quickshell
import Quickshell.Wayland
import qs.config

// Invisible strip that reserves screen space for the full bar, so windows do not tile underneath it.
// The notch window itself spans the whole screen, which cannot carry an exclusive zone.
PanelWindow {
	required property var modelData
	screen: modelData

	readonly property string edge: Settings.placementFor("").split(":")[0]
	readonly property bool vertical: edge === "left" || edge === "right"

	anchors.top: edge !== "bottom"
	anchors.bottom: edge !== "top"
	anchors.left: edge !== "right"
	anchors.right: edge !== "left"

	implicitWidth: vertical ? Settings.barHeight : 0
	implicitHeight: vertical ? 0 : Settings.barHeight
	color: "transparent"
	exclusionMode: ExclusionMode.Normal
	exclusiveZone: Settings.barHeight
	mask: Region {}

	WlrLayershell.namespace: "notch-reserve"
	WlrLayershell.layer: WlrLayer.Top
}
