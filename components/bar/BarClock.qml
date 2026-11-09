import QtQuick
import qs.config
import qs.services
import qs.components

Txt {
	id: root
	property var cfg: ({})
	readonly property var c: BarLayout.resolve("clock", cfg)
	property date now: new Date()

	readonly property string timeText: Qt.formatTime(now, c.showSeconds ? (Settings.use24h ? "HH:mm:ss" : "h:mm:ss AP") : (Settings.use24h ? "HH:mm" : "h:mm AP"))
	readonly property string dateText: Qt.formatDate(now, c.dateFormat)
	text: c.showDate && c.showTime ? dateText + "  " + timeText : c.showDate ? dateText : timeText
	font.pixelSize: 13
	font.weight: Font.Medium
	elide: Text.ElideNone

	Timer {
		interval: root.c.showSeconds ? 1000 : 5000
		running: root.visible
		repeat: true
		triggeredOnStart: true
		onTriggered: root.now = new Date()
	}
	MouseArea {
		anchors.fill: parent
		onClicked: NotchCtl.toggle("calendar")
	}
}
