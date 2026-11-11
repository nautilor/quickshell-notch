import QtQuick
import qs.config
import qs.services
import qs.components

// Full-bar content: the user's items in three zones.
Item {
	id: root

	implicitHeight: 44

	component Zone: Row {
		id: zone
		required property string name
		spacing: 8
		Repeater {
			model: BarLayout.items(zone.name)
			Loader {
				required property var modelData
				anchors.verticalCenter: parent.verticalCenter
				source: BarLayout.types[modelData.type] ? BarLayout.types[modelData.type].source : ""
				onLoaded: item.cfg = modelData.cfg || {}
			}
		}
	}

	Zone {
		name: "left"
		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
	}
	Zone {
		name: "center"
		anchors.centerIn: parent
	}
	Zone {
		name: "right"
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
	}
}
