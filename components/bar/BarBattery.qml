import QtQuick
import qs.config
import qs.services
import qs.components

Row {
	id: root
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("battery", cfg)

	visible: Battery.present
	spacing: 2
	Icon {
		name: Battery.icon
		size: 18
		fill: 1
		color: Battery.color
		anchors.verticalCenter: parent.verticalCenter
	}
	Txt {
		visible: root.c.showPercent
		text: Battery.percent + "%"
		font.pixelSize: 12
		font.weight: Font.Medium
		color: Battery.color
		elide: Text.ElideNone
		anchors.verticalCenter: parent.verticalCenter
	}
}
