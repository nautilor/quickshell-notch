import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// One list row of the network window: icon, title + subtitle, optional trailing controls.
Item {
	id: root

	property string icon
	property string title
	property string subtitle
	property bool active: false
	property bool busy: false
	property bool clickable: true
	property real iconOpacity: 1
	default property alias trailing: slot.data

	signal clicked

	implicitHeight: 48

	Rectangle {
		anchors.fill: parent
		radius: Theme.r(16)
		color: root.active ? Theme.primaryContainer : Theme.surfaceFg
		opacity: root.active ? 1 : (area.containsMouse && root.clickable ? 0.08 : 0)
	}

	MouseArea {
		id: area
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
		onClicked: if (root.clickable)
			root.clicked()
	}

	RowLayout {
		anchors.fill: parent
		anchors.leftMargin: 14
		anchors.rightMargin: 8
		spacing: 12

		Icon {
			name: root.icon
			size: 22
			opacity: root.iconOpacity
			color: root.active ? Theme.primaryContainerFg : Theme.surfaceFg
		}
		ColumnLayout {
			Layout.fillWidth: true
			spacing: 0
			Txt {
				Layout.fillWidth: true
				text: root.title
				font.weight: Font.Medium
				color: root.active ? Theme.primaryContainerFg : Theme.surfaceFg
			}
			Txt {
				Layout.fillWidth: true
				visible: root.subtitle !== ""
				text: root.subtitle
				font.pixelSize: 12
				opacity: 0.8
				color: root.active ? Theme.primaryContainerFg : Theme.surfaceVariantFg
			}
		}
		Icon {
			visible: root.busy
			name: "refresh"
			size: 18
			color: root.active ? Theme.primaryContainerFg : Theme.surfaceVariantFg
			RotationAnimator on rotation {
				running: root.busy
				from: 0
				to: 360
				duration: 900
				loops: Animation.Infinite
			}
		}
		RowLayout {
			id: slot
			spacing: 4
		}
	}
}
