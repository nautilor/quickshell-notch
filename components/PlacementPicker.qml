import QtQuick
import qs.config

// Edge + position along it, as "edge:align". With allowInherit an extra "Same as notch" chip sets "".
Column {
	id: root

	property string value
	property bool allowInherit: false
	signal picked(string value)

	readonly property string edge: value === "" ? "" : value.split(":")[0]
	readonly property string align: value === "" ? "" : value.split(":")[1]
	readonly property bool vertical: edge === "left" || edge === "right"

	spacing: 8

	component Chip: Rectangle {
		id: chip
		property string label
		property bool current
		signal clicked
		width: 100
		height: 38
		radius: current ? Theme.radiusSmall : Theme.radiusMedium
		color: current ? Theme.primaryContainer : Theme.surfaceContainerHigh
		Behavior on radius {
			NumberAnimation {
				duration: Theme.durShort
			}
		}
		Txt {
			anchors.centerIn: parent
			text: chip.label
			font.pixelSize: 12
			color: chip.current ? Theme.primaryContainerFg : Theme.surfaceVariantFg
		}
		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: chip.clicked()
		}
	}

	Row {
		spacing: 8
		Chip {
			visible: root.allowInherit
			label: "Same as notch"
			width: 120
			current: root.value === ""
			onClicked: root.picked("")
		}
		Repeater {
			model: [{ id: "top", name: "Top" }, { id: "bottom", name: "Bottom" }, { id: "left", name: "Left" }, { id: "right", name: "Right" }]
			Chip {
				required property var modelData
				label: modelData.name
				current: root.edge === modelData.id
				onClicked: root.picked(modelData.id + ":" + (root.align || "center"))
			}
		}
	}

	Row {
		spacing: 8
		visible: root.value !== ""
		Repeater {
			model: [{ id: "start", name: root.vertical ? "Top" : "Left" }, { id: "center", name: "Center" }, { id: "end", name: root.vertical ? "Bottom" : "Right" }]
			Chip {
				required property var modelData
				label: modelData.name
				current: root.align === modelData.id
				onClicked: root.picked(root.edge + ":" + modelData.id)
			}
		}
	}
}
