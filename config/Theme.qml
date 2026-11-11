pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Material 3 Expressive tokens. Tonal roles are derived from one seed hue (Settings.hue),
// unless a colour scheme is selected (Settings.colorscheme), which supplies the colours instead.
Singleton {
	id: root

	readonly property real h: Settings.hue
	readonly property var st: UiStyles.current
	// colour scheme / wallpaper colours win, then the style's own palette, else the hue-derived tonal palette
	readonly property var pal: Colorschemes.palette ?? UiStyles.palette
	function tone(s, l, hueShift) {
		return Qt.hsla((h + (hueShift || 0) + 1) % 1, s, l, 1);
	}

	// surface opacity (Settings): the notch takes it as is, cards on top fade less so text stays readable
	readonly property real opacity: Math.max(0.2, Math.min(1, Settings.surfaceOpacity))
	readonly property real cardOpacity: 1 - (1 - opacity) * 0.55

	// surfaces (the notch itself stays near-black so it merges with the screen edge)
	readonly property color notchSolid: pal ? pal.notch : tone(0.12, 0.035)
	readonly property color notch: Qt.alpha(notchSolid, opacity)
	readonly property color surfaceContainerLow: Qt.alpha(pal ? pal.surfaceContainerLow : tone(0.18, 0.095), cardOpacity)
	readonly property color surfaceContainer: Qt.alpha(pal ? pal.surfaceContainer : tone(0.19, 0.135), cardOpacity)
	readonly property color surfaceContainerHigh: Qt.alpha(pal ? pal.surfaceContainerHigh : tone(0.2, 0.175), cardOpacity)
	readonly property color surfaceContainerHighest: Qt.alpha(pal ? pal.surfaceContainerHighest : tone(0.2, 0.22), cardOpacity)

	readonly property color primary: pal ? pal.primary : tone(0.55, 0.76)
	readonly property color primaryFg: pal ? pal.primaryFg : tone(0.65, 0.14)
	readonly property color primaryContainer: pal ? pal.primaryContainer : tone(0.45, 0.26)
	readonly property color primaryContainerFg: pal ? pal.primaryContainerFg : tone(0.65, 0.88)

	readonly property color secondaryContainer: pal ? pal.secondaryContainer : tone(0.22, 0.28, 0.02)
	readonly property color secondaryContainerFg: pal ? pal.secondaryContainerFg : tone(0.35, 0.88, 0.02)

	readonly property color tertiary: pal ? pal.tertiary : tone(0.5, 0.79, 0.16)
	readonly property color tertiaryFg: pal ? pal.tertiaryFg : tone(0.6, 0.15, 0.16)
	readonly property color tertiaryContainer: pal ? pal.tertiaryContainer : tone(0.38, 0.28, 0.16)
	readonly property color tertiaryContainerFg: pal ? pal.tertiaryContainerFg : tone(0.6, 0.9, 0.16)

	readonly property color error: pal ? pal.error : "#f2b8b5"
	readonly property color errorFg: pal ? pal.errorFg : "#601410"
	readonly property color errorContainer: pal ? pal.errorContainer : "#8c1d18"
	readonly property color errorContainerFg: pal ? pal.errorContainerFg : "#f9dedc"

	readonly property color surfaceFg: pal ? pal.surfaceFg : tone(0.1, 0.92)
	readonly property color surfaceVariantFg: pal ? pal.surfaceVariantFg : tone(0.1, 0.74)
	readonly property color outline: pal ? pal.outline : tone(0.08, 0.48)
	readonly property color outlineVariant: pal ? pal.outlineVariant : tone(0.1, 0.25)

	// type
	// JetBrainsMono Nerd Font (proportional variant) for text and for the Material Design Icons glyphs
	readonly property string iconFont: "JetBrainsMono Nerd Font Propo"
	readonly property string font: UiStyles.font

	// shape scale (multiplied by the style's shape factor)
	function r(n) {
		return Math.round(n * st.shape);
	}
	// radius for a control of height h: a full pill, or a rounded rectangle in styles without pills
	function pillRadius(h) {
		return st.pill ? h / 2 : Math.min(h / 2, st.ctl);
	}
	readonly property int radiusSmall: r(14)
	readonly property int radiusMedium: r(22)
	readonly property int radiusLarge: r(32)
	readonly property int radiusXLarge: r(40)
	// connected button groups: big radius on the outer edge, small on the inner edges
	readonly property int radiusInner: Math.max(3, r(8))
	// outline width of controls (Fluent-style hairlines)
	readonly property int controlBorder: st.border
	readonly property real pressScale: st.press
	// switch: size, inset of the thumb, check/close icon that grows on press (Expressive / Material only)
	readonly property bool fancySwitch: st.swIcons
	readonly property int switchW: st.sw[0]
	readonly property int switchH: st.sw[1]
	readonly property int switchInset: st.swInset
	readonly property bool switchWhiteKnob: st.swWhiteKnob
	// slider: "wave" (Expressive), "pill" (gapped handle) or "knob" (round thumb, solid track)
	readonly property string sliderKind: st.slider
	readonly property int sliderTrack: st.track
	readonly property int sliderKnob: st.knob

	// type scale (per style): label / body / title / headline
	readonly property int textLabel: st.text[0]
	readonly property int textBody: st.text[1]
	readonly property int textTitle: st.text[2]
	readonly property int textHeadline: st.text[3]

	// motion: emphasized easing + springs that overshoot slightly (the "expressive" feel)
	readonly property var emphasized: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
	readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
	readonly property int durShort: Math.round(150 * st.dur)
	readonly property int durMedium: Math.round(300 * st.dur)
	readonly property int durLong: Math.round(500 * st.dur)
	readonly property real springBouncy: st.spring
	readonly property real dampBouncy: st.damp
	readonly property real springSoft: st.springSoft
	readonly property real dampSoft: st.dampSoft
}
