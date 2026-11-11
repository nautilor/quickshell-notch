import QtQuick
import qs.config
import qs.services
import qs.components

BarCapsule {
	id: root
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("clock", cfg)
	property date now: new Date()

	readonly property string timeText: Qt.formatTime(now, c.showSeconds ? (Settings.use24h ? "HH:mm:ss" : "h:mm:ss AP") : (Settings.use24h ? "HH:mm" : "h:mm AP"))
	readonly property string dateText: Qt.formatDate(now, c.dateFormat)

	hoverable: true
	hovered: mouse.containsMouse
	padding: 14

	Txt {
		anchors.verticalCenter: parent.verticalCenter
		text: root.c.showDate && root.c.showTime ? root.dateText + "  " + root.timeText : root.c.showDate ? root.dateText : root.timeText
		font.pixelSize: 14
		font.weight: Font.DemiBold
		elide: Text.ElideNone
	}

	Timer {
		interval: root.c.showSeconds ? 1000 : 5000
		running: root.visible
		repeat: true
		triggeredOnStart: true
		onTriggered: root.now = new Date()
	}
	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: NotchCtl.toggle("calendar")
	}
}
