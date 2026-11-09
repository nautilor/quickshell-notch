import QtQuick
import qs.config
import qs.services
import qs.components

// Next calendar event; click opens the week view.
Rectangle {
	id: root

	readonly property var next: Gcal.upcoming.length > 0 ? Gcal.upcoming[0] : null

	function when(ev) {
		const now = new Date();
		const day = Gcal.sameDay(ev.s, now) || ev.s < now ? "Today" : Gcal.sameDay(ev.s, Gcal.addDays(now, 1)) ? "Tomorrow" : Qt.formatDate(ev.s, "ddd d MMM");
		return day + " · " + Gcal.timeLabel(ev);
	}

	radius: Theme.radiusMedium
	color: Theme.tertiaryContainer

	Rectangle {
		anchors.fill: parent
		radius: parent.radius
		color: Theme.tertiaryContainerFg
		opacity: area.pressed ? 0.12 : area.containsMouse ? 0.08 : 0
	}

	Rectangle {
		id: badge
		// scales down in short containers (dock) so it keeps a margin; 40px otherwise
		width: Math.min(40, root.height - 16)
		height: width
		radius: width * 0.35
		color: Theme.tertiary
		anchors.left: parent.left
		anchors.leftMargin: Math.min(12, (root.height - width) / 2)
		anchors.verticalCenter: parent.verticalCenter
		Icon {
			anchors.centerIn: parent
			name: "event"
			fill: 1
			size: badge.width * 0.55
			color: Theme.tertiaryFg
		}
	}

	Column {
		anchors.left: badge.right
		anchors.leftMargin: Math.min(12, (root.height - badge.width) / 2 + 2)
		anchors.right: parent.right
		anchors.rightMargin: 12
		anchors.verticalCenter: parent.verticalCenter
		spacing: 1
		Txt {
			width: parent.width
			text: root.next ? root.next.title : "No upcoming events"
			font.weight: Font.Bold
			color: Theme.tertiaryContainerFg
		}
		Txt {
			width: parent.width
			text: root.next ? root.when(root.next) : "Enjoy the quiet"
			font.pixelSize: 12
			color: Theme.tertiaryContainerFg
			opacity: 0.8
		}
	}

	MouseArea {
		id: area
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: NotchCtl.tab = "calendar"
	}
}
