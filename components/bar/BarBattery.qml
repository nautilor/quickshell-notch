import QtQuick
import qs.config
import qs.services
import qs.components

BarCapsule {
	id: root
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("battery", cfg)

	visible: Battery.present
	padding: 10
	Row {
		spacing: 3
		anchors.verticalCenter: parent.verticalCenter
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
			font.pixelSize: 13
			font.weight: Font.DemiBold
			color: Battery.color
			elide: Text.ElideNone
			anchors.verticalCenter: parent.verticalCenter
		}
	}
}
