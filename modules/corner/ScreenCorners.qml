import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Rounds the corners of one screen: four inverted quarter-circles drawn over everything, click-through.
PanelWindow {
	id: root

	required property var modelData
	screen: modelData

	readonly property real radius: Settings.cornerRadius
	readonly property color fill: Theme.notchSolid

	// with the full bar showing, the corners on its edge sit just inside the bar instead of under it
	readonly property string barEdge: Settings.placementFor("").split(":")[0]
	property real off: NotchCtl.barOn[screen.name] ? Settings.barHeight : 0
	Behavior on off {
		NumberAnimation {
			duration: Theme.durMedium
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Theme.emphasized
		}
	}

	anchors {
		left: true
		top: true
		right: true
		bottom: true
	}
	color: "transparent"
	exclusionMode: ExclusionMode.Ignore
	mask: Region {}

	WlrLayershell.namespace: "notch-corners"
	WlrLayershell.layer: WlrLayer.Overlay

	component CornerShape: Shape {
		id: shape
		preferredRendererType: Shape.CurveRenderer
		width: root.radius
		height: root.radius

		ShapePath {
			strokeWidth: -1
			fillColor: root.fill
			startX: 0
			startY: 0

			PathLine {
				x: shape.width
				y: 0
			}
			PathArc {
				x: 0
				y: shape.height
				radiusX: shape.width
				radiusY: shape.height
				direction: PathArc.Counterclockwise
			}
			PathLine {
				x: 0
				y: 0
			}
		}
	}

	CornerShape {
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.topMargin: root.barEdge === "top" ? root.off : 0
		anchors.leftMargin: root.barEdge === "left" ? root.off : 0
	}
	CornerShape {
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.topMargin: root.barEdge === "top" ? root.off : 0
		anchors.rightMargin: root.barEdge === "right" ? root.off : 0
		rotation: 90
	}
	CornerShape {
		anchors.bottom: parent.bottom
		anchors.right: parent.right
		anchors.bottomMargin: root.barEdge === "bottom" ? root.off : 0
		anchors.rightMargin: root.barEdge === "right" ? root.off : 0
		rotation: 180
	}
	CornerShape {
		anchors.bottom: parent.bottom
		anchors.left: parent.left
		anchors.bottomMargin: root.barEdge === "bottom" ? root.off : 0
		anchors.leftMargin: root.barEdge === "left" ? root.off : 0
		rotation: 270
	}
}
