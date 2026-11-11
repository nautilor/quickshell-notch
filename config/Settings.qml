pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent user settings, stored as JSON in ~/.config/quickshell-notch/settings.json.
Singleton {
	id: root

	readonly property string configDir: Quickshell.env("HOME") + "/.config/quickshell-notch"

	property alias hue: adapter.hue
	property alias colorscheme: adapter.colorscheme
	property alias uiStyle: adapter.uiStyle
	property alias surfaceOpacity: adapter.surfaceOpacity
	property alias builtinLock: adapter.builtinLock
	property alias lockPam: adapter.lockPam
	property alias lockPamDir: adapter.lockPamDir
	property alias lockWallpaper: adapter.lockWallpaper
	property alias lockAvatar: adapter.lockAvatar
	property alias hoverOpen: adapter.hoverOpen
	property alias dnd: adapter.dnd
	property alias homeLayout: adapter.homeLayout
	property alias homeStyle: adapter.homeStyle
	property alias homeOnHover: adapter.homeOnHover
	property alias screenCorners: adapter.screenCorners
	property alias cornerRadius: adapter.cornerRadius
	property alias autohide: adapter.autohide
	property alias fullBar: adapter.fullBar
	property alias barLayout: adapter.barLayout
	property alias barHeight: adapter.barHeight
	property alias notifTimeout: adapter.notifTimeout
	property alias screenName: adapter.screenName
	property alias allScreens: adapter.allScreens
	property alias weekStartsMonday: adapter.weekStartsMonday
	property alias use24h: adapter.use24h
	property alias showClock: adapter.showClock
	property alias showDate: adapter.showDate
	property alias showBattery: adapter.showBattery
	property alias showDateHome: adapter.showDateHome
	property alias caffeineOnMessage: adapter.caffeineOnMessage
	property alias caffeineOffMessage: adapter.caffeineOffMessage
	property alias micOnMessage: adapter.micOnMessage
	property alias micOffMessage: adapter.micOffMessage
	property alias notchEdge: adapter.notchEdge
	property alias notchAlign: adapter.notchAlign
	property alias placements: adapter.placements
	property alias dockEnabled: adapter.dockEnabled
	property alias dockEdge: adapter.dockEdge
	property alias dockAutohide: adapter.dockAutohide
	property alias dockAllScreens: adapter.dockAllScreens
	property alias dockIconSize: adapter.dockIconSize
	property alias dockPinned: adapter.dockPinned
	property alias dockIcons: adapter.dockIcons
	property alias wallpaper: adapter.wallpaper
	property alias wallpaperColors: adapter.wallpaperColors
	property alias wallpaperTintBg: adapter.wallpaperTintBg
	property alias recordDir: adapter.recordDir
	property alias recordEncoder: adapter.recordEncoder
	property alias launchCounts: adapter.launchCounts

	// "edge:align" the notch sits at when it opens for `ctx` (a tab id, "popup", or "" for the notch itself)
	function placementFor(ctx) {
		const p = ctx ? (placements || {})[ctx] : "";
		return p ? p : notchEdge + ":" + notchAlign;
	}

	function placementLabel(p) {
		const [edge, align] = p.split(":");
		const side = { top: "Top", bottom: "Bottom", left: "Left", right: "Right" }[edge];
		const vertical = edge === "left" || edge === "right";
		const al = align === "start" ? (vertical ? "top" : "left") : align === "end" ? (vertical ? "bottom" : "right") : "";
		return al === "" ? side : side + " · " + al;
	}

	function setPlacement(ctx, value) {
		const m = Object.assign({}, placements || {});
		if (value === "")
			delete m[ctx];
		else
			m[ctx] = value;
		placements = m;
	}

	property bool dirReady: false

	Process {
		running: true
		command: ["mkdir", "-p", root.configDir]
		onExited: root.dirReady = true
	}

	FileView {
		path: root.dirReady ? root.configDir + "/settings.json" : ""
		watchChanges: true
		onFileChanged: reload()
		onAdapterUpdated: writeAdapter()
		onLoadFailed: error => {
			if (error === FileViewError.FileNotFound)
				writeAdapter();
		}

		adapter: JsonAdapter {
			id: adapter

			property real hue: 0.53
			// screen edge the notch is attached to: "top" | "bottom" | "left" | "right"
			property string notchEdge: "top"
			// position along that edge: "start" (left / top), "center" or "end" (right / bottom)
			property string notchAlign: "center"
			// where the notch opens for a tab or the notification popup ("edge:align"); missing = same as the notch
			// keys: tab ids (apps, clipboard, calendar, notifications, power, record, settings) and "popup"
			property var placements: ({})
			// wallpaper chosen from ~/Pictures/Wallpapers; with wallpaperColors the theme is generated from it
			property string wallpaper: ""
			property bool wallpaperColors: false
			// with wallpaperColors: tint the near-black background with the wallpaper colour
			property bool wallpaperTintBg: false
			// dock
			property bool dockEnabled: true
			property string dockEdge: "bottom"
			property bool dockAutohide: false
			property bool dockAllScreens: false
			property int dockIconSize: 44
			// desktop entry ids, in dock order
			property var dockPinned: []
			// per-app custom icon: desktop entry id / app id -> icon theme name or image path
			property var dockIcons: ({})
			// id (file name without .json) of a colour scheme; empty = tonal palette from hue
			property string colorscheme: ""
			// UI style (shapes, motion, font, colours): expressive | material | macos | gnome | windows11
			property string uiStyle: "expressive"
			// 0.2 - 1: opacity of the notch, bar and dock surfaces; below 1 they can be blurred with a Hyprland layerrule
			property real surfaceOpacity: 1.0
			// built-in lock screen: used by the Power tab and `notch lock`
			property bool builtinLock: true
			// PAM service used to check the password (must exist in /etc/pam.d)
			property string lockPam: "hyprlock"
			// folder holding the PAM service file; empty = /etc/pam.d
			property string lockPamDir: ""
			property string lockWallpaper: ""
			property string lockAvatar: ""
			property bool hoverOpen: true
			property bool dnd: false
			// customised Home dashboard: {v: 1, items: [...]}; empty = built-in default
			property var homeLayout: ({})
			// Home layout: "grid" (editable widgets), "control" (Control Center tiles) or "strip" (one wide row)
			property string homeStyle: "grid"
			property bool homeOnHover: true
			property bool screenCorners: true
			property real cornerRadius: 20
			property bool autohide: false
			// idle notch stretches along the whole edge as a bar; it still opens as a notch
			property bool fullBar: false
			// items of the full bar: {v: 1, left: [...], center: [...], right: [...]}; empty = default
			property var barLayout: ({})
			// thickness of the full bar in pixels
			property int barHeight: 44
			property int notifTimeout: 5000
			property string screenName: ""
			property bool allScreens: false
			property bool weekStartsMonday: true
			property bool use24h: true
			property bool showClock: false
			property bool showDate: false
			property bool showBattery: false
			property bool showDateHome: false
			property string caffeineOnMessage: "Caffeine on · staying awake"
			property string caffeineOffMessage: "Caffeine off"
			property string micOnMessage: "Microphone live"
			property string micOffMessage: "Microphone muted"
			// folder for screen recordings; empty = ~/Videos/Recordings
			property string recordDir: ""
			// screen recording encoder: "auto" (NVENC on NVIDIA GPUs, else CPU) or "cpu"
			property string recordEncoder: "auto"
			property var launchCounts: ({})
		}
	}
}
