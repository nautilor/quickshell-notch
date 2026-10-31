import QtQuick
import qs.config

// Top / Bottom / Left / Right chooser.
Row {
	id: root

	property string value
	signal picked(string edge)

	spacing: 8

	Repeater {
		model: [{ id: "top", name: "Top" }, { id: "bottom", name: "Bottom" }, { id: "left", name: "Left" }, { id: "right", name: "Right" }]
		Rectangle {
			id: chip
			required property var modelData
			readonly property bool current: root.value === modelData.id
			width: 100
			height: 44
			radius: current ? Theme.radiusSmall : Theme.radiusMedium
			color: current ? Theme.primaryContainer : Theme.surfaceContainerHigh
			Behavior on radius {
				NumberAnimation {
					duration: Theme.durShort
				}
			}
			Txt {
				anchors.centerIn: parent
				text: chip.modelData.name
				font.pixelSize: 12
				color: chip.current ? Theme.primaryContainerFg : Theme.surfaceVariantFg
			}
			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: root.picked(chip.modelData.id)
			}
		}
	}
}
