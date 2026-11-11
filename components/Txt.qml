import QtQuick
import qs.config

// role: "label" | "body" | "title" | "headline" (M3 type scale). Explicit font.* still wins.
Text {
	property string role: "body"

	color: Theme.surfaceFg
	font.family: Theme.font
	font.pixelSize: role === "headline" ? Theme.textHeadline : role === "title" ? Theme.textTitle : role === "label" ? Theme.textLabel : Theme.textBody
	font.weight: role === "headline" || role === "title" ? Theme.st.titleWeight : Font.Normal
	elide: Text.ElideRight
	renderType: Text.NativeRendering
}
