import QtQuick
import qs.config
import qs.components

// Example custom Home widget. Copy to ~/.config/quickshell-notch/widgets/Hello.qml,
// then add a "QML file" widget on the Home tab and set its file name to Hello.qml.
// The root item is sized to the widget. `cfg` holds the widget's own settings.
Rectangle {
	property var cfg: ({})

	color: Theme.tertiaryContainer
	radius: Theme.radiusMedium

	Txt {
		anchors.centerIn: parent
		text: "Hello from QML"
		color: Theme.tertiaryContainerFg
		font.weight: Font.Bold
	}
}
