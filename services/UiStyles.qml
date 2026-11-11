pragma Singleton

import QtQuick
import Quickshell
import qs.config

// UI styles: each one is a bundle of shape, motion, font and (optionally) colour tokens that Theme exposes.
// `json` is a colour scheme in the Colorschemes format; null keeps the accent-hue tonal palette.
// A selected colour scheme or wallpaper colours still win over the style's own palette.
Singleton {
	id: root

	readonly property var styles: [
		{
			id: "expressive",
			name: "Expressive",
			blurb: "Material 3 Expressive · bouncy, very round",
			json: null,
			shape: 1.0, pill: true, ctl: 12, border: 0, press: 0.96, accentable: true,
			sw: [56, 34], swIcons: true, swInset: 4, swWhiteKnob: false,
			slider: "wave", track: 5, knob: 0,
			text: [12, 14, 16, 22], titleWeight: Font.DemiBold,
			spring: 3.4, damp: 0.30, springSoft: 4.5, dampSoft: 0.42, dur: 1.0,
			fonts: []
		},
		{
			id: "material",
			name: "Material 3",
			blurb: "Calm Material You · rounded, gentle motion",
			json: null,
			shape: 0.75, pill: true, ctl: 12, border: 0, press: 0.98, accentable: true,
			sw: [52, 32], swIcons: true, swInset: 4, swWhiteKnob: false,
			slider: "pill", track: 4, knob: 0,
			text: [12, 14, 16, 22], titleWeight: Font.Medium,
			spring: 4.5, damp: 0.62, springSoft: 5, dampSoft: 0.75, dur: 1.0,
			fonts: ["Roboto Flex", "Roboto", "Google Sans"]
		},
		{
			// values from the macOS 27 UI kit (dark): window #1e1e1e, blue #0091ff, labels white 85/55/25 %
			id: "macos",
			name: "macOS",
			blurb: "Graphite, system blue, capsule controls",
			json: {
				background: "#1e1e1e", foreground: "#f5f5f5", primary: "#0091ff", secondary: "#3cd3fe", tertiary: "#6d7cff", error: "#ff4245",
				notch: "#000000", surfaceContainerLow: "#1e1e1e", surfaceContainer: "#282828", surfaceContainerHigh: "#303030", surfaceContainerHighest: "#3a3a3a",
				primaryFg: "#ffffff", primaryContainer: "#0a3d75", primaryContainerFg: "#d6e9ff", secondaryContainer: "#303030", secondaryContainerFg: "#f5f5f5",
				surfaceVariantFg: "#9b9b9b", outline: "#5a5a5a", outlineVariant: "#3a3a3a"
			},
			shape: 0.85, pill: true, ctl: 6, border: 0, press: 0.98, accentable: false,
			sw: [54, 26], swIcons: false, swInset: 2, swWhiteKnob: true,
			slider: "knob", track: 6, knob: 20,
			text: [11, 13, 15, 20], titleWeight: Font.DemiBold,
			spring: 5, damp: 0.58, springSoft: 5.5, dampSoft: 0.7, dur: 1.0,
			fonts: ["SF Pro", "SF Pro Text", "SF Pro Display", "Inter", "Helvetica Neue"]
		},
		{
			// values from the Adwaita kit: buttons and entries 6, cards and windows 12, slider track 4, accent #3584e4
			id: "gnome",
			name: "GNOME",
			blurb: "Adwaita dark, flat, no bounce",
			json: {
				background: "#242424", foreground: "#ffffff", primary: "#3584e4", secondary: "#78aeed", tertiary: "#8ff0a4", error: "#ff7b63",
				notch: "#1e1e1e", surfaceContainerLow: "#2a2a2a", surfaceContainer: "#303030", surfaceContainerHigh: "#383838", surfaceContainerHighest: "#444444",
				primaryFg: "#ffffff", primaryContainer: "#1c3f6b", primaryContainerFg: "#d3e5fb", secondaryContainer: "#383838", secondaryContainerFg: "#ffffff",
				surfaceVariantFg: "#c0bfbc", outline: "#77767b", outlineVariant: "#3d3d3d"
			},
			shape: 0.55, pill: false, ctl: 6, border: 0, press: 0.98, accentable: false,
			sw: [46, 26], swIcons: false, swInset: 3, swWhiteKnob: true,
			slider: "knob", track: 4, knob: 20,
			text: [11, 14, 16, 22], titleWeight: Font.Bold,
			spring: 6, damp: 0.92, springSoft: 6, dampSoft: 0.95, dur: 0.9,
			fonts: ["Adwaita Sans", "Cantarell", "Inter"]
		},
		{
			// values from the Windows 11 kit: controls 4, flyouts and cards 8, 1 px strokes, rail 4, accent #60cdff
			id: "windows11",
			name: "Windows 11",
			blurb: "Fluent, thin outlines, tight corners",
			json: {
				background: "#202020", foreground: "#ffffff", primary: "#60cdff", secondary: "#4cc2ff", tertiary: "#c6a1f2", error: "#ff99a4",
				notch: "#1b1b1b", surfaceContainerLow: "#242424", surfaceContainer: "#2b2b2b", surfaceContainerHigh: "#333333", surfaceContainerHighest: "#3d3d3d",
				primaryFg: "#000000", primaryContainer: "#0b3d55", primaryContainerFg: "#c9efff", secondaryContainer: "#333333", secondaryContainerFg: "#ffffff",
				surfaceVariantFg: "#c8c8c8", outline: "#8a8a8a", outlineVariant: "#454545"
			},
			shape: 0.5, pill: false, ctl: 4, border: 1, press: 0.99, accentable: false,
			sw: [40, 20], swIcons: false, swInset: 4, swWhiteKnob: false,
			slider: "knob", track: 4, knob: 18,
			text: [12, 14, 16, 20], titleWeight: Font.DemiBold,
			spring: 8, damp: 1.0, springSoft: 8, dampSoft: 1.0, dur: 0.75,
			fonts: ["Segoe UI Variable", "Segoe UI", "Selawik", "Inter"]
		}
	]

	readonly property var current: styles.find(s => s.id === Settings.uiStyle) ?? styles[0]
	readonly property var palette: current.json ? Colorschemes.build(current.id, current.json).palette : null
	readonly property string font: pickFont(current.fonts)

	function pickFont(list) {
		const have = Qt.fontFamilies();
		for (const f of list) {
			if (have.indexOf(f) >= 0)
				return f;
		}
		return "JetBrainsMono Nerd Font Propo";
	}

	// small swatch row for the style picker: [surface, primary, secondary, tertiary]
	function preview(s) {
		if (!s.json)
			return [Theme.tone(0.18, 0.15), Qt.hsla(Settings.hue, 0.55, 0.76, 1), Qt.hsla((Settings.hue + 0.02) % 1, 0.35, 0.88, 1), Qt.hsla((Settings.hue + 0.16) % 1, 0.5, 0.79, 1)];
		return [s.json.surfaceContainerHigh, s.json.primary, s.json.secondary, s.json.tertiary];
	}
}
