pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Items of the full bar, in three zones (left, centre, right). Stored in Settings.barLayout as
// {v: 1, left: [{type, cfg}], center: [...], right: [...]}; empty = the default below.
// schema kinds: text | bool | choice (options) | icon
Singleton {
	id: root

	function src(name) {
		return Qt.resolvedUrl("../components/bar/" + name + ".qml");
	}

	readonly property var zones: ["left", "center", "right"]
	readonly property var zoneNames: ({ left: "Left", center: "Center", right: "Right" })

	readonly property var types: ({
			"workspace": { title: "Workspace", icon: "dashboard", desc: "Current workspace number", source: src("BarWorkspace"), schema: [] },
			"workspaces": { title: "Workspaces", icon: "apps", desc: "Focused, visible and occupied workspaces", source: src("BarWorkspaces"), schema: [] },
			"media": {
				title: "Media", icon: "music_note", desc: "Cover art and controls of the playing track", source: src("BarMedia"),
				schema: [
					{ key: "showTitle", label: "Show title and artist", kind: "bool", def: false },
					{ key: "showControls", label: "Show previous / play / next", kind: "bool", def: true },
					{ key: "alwaysShow", label: "Show when nothing plays", kind: "bool", def: false }
				]
			},
			"clock": {
				title: "Clock", icon: "schedule", desc: "Time and date", source: src("BarClock"),
				schema: [
					{ key: "showTime", label: "Show time", kind: "bool", def: true },
					{ key: "showSeconds", label: "Show seconds", kind: "bool", def: false },
					{ key: "showDate", label: "Show date", kind: "bool", def: false },
					{ key: "dateFormat", label: "Date format", kind: "text", def: "ddd d MMM", placeholder: "ddd d MMM" }
				]
			},
			"tray": {
				title: "System tray", icon: "tray", desc: "Tray icons; right click for the app menu", source: src("BarTray"),
				schema: [
					{ key: "size", label: "Icon button size", kind: "choice", options: [22, 26, 30], def: 26 }
				]
			},
			"battery": {
				title: "Battery", icon: "battery_full", desc: "Charge level", source: src("BarBattery"),
				schema: [{ key: "showPercent", label: "Show percentage", kind: "bool", def: false }]
			},
			"volume": {
				title: "Volume", icon: "volume_up", desc: "Click to mute, scroll to change", source: src("BarVolume"),
				schema: [{ key: "showPercent", label: "Show percentage", kind: "bool", def: false }]
			},
			"status": { title: "Status icons", icon: "widgets", desc: "Recording, caffeine, muted mic, do not disturb", source: src("BarStatus"), schema: [] },
			"notifications": {
				title: "Notifications", icon: "notifications", desc: "Unread count; click opens the list", source: src("BarNotifications"),
				schema: [{ key: "alwaysShow", label: "Show with no notifications", kind: "bool", def: false }]
			},
			"visualizer": { title: "Visualizer", icon: "music_note", desc: "Equalizer bars while music plays", source: src("BarVisualizer"), schema: [] },
			"toggle": {
				title: "Quick toggle", icon: "tune", desc: "Wi-Fi, Bluetooth, caffeine, microphone or do not disturb", source: src("BarToggle"),
				schema: [{ key: "kind", label: "Toggle", kind: "choice", options: ["wifi", "bluetooth", "caffeine", "mic", "dnd"], def: "wifi" }]
			},
			"shortcut": {
				title: "Shortcut", icon: "search", desc: "Opens the launcher, clipboard, calendar, ...", source: src("BarShortcut"),
				schema: [
					{ key: "tab", label: "Opens", kind: "choice", options: ["apps", "clipboard", "calendar", "notifications", "power", "record", "settings", "home"], def: "apps" },
					{ key: "icon", label: "Icon", kind: "icon", def: "apps" },
					{ key: "label", label: "Label", kind: "text", def: "", placeholder: "optional" }
				]
			},
			"command": {
				title: "Command button", icon: "touch_app", desc: "Runs a shell command", source: src("BarCommand"),
				schema: [
					{ key: "icon", label: "Icon", kind: "icon", def: "rocket" },
					{ key: "label", label: "Label", kind: "text", def: "", placeholder: "optional" },
					{ key: "command", label: "Command", kind: "text", def: "", placeholder: "notify-send hello" }
				]
			}
		})

	readonly property var order: ["workspace", "workspaces", "media", "clock", "tray", "battery", "volume", "status", "notifications", "visualizer", "toggle", "shortcut", "command"]

	// what the bar showed before it was customisable
	readonly property var defaults: ({
			left: [{ type: "workspace", cfg: {} }, { type: "media", cfg: {} }],
			center: Settings.showClock || Settings.showDate ? [{ type: "clock", cfg: { showTime: Settings.showClock, showDate: Settings.showDate } }] : [],
			right: [{ type: "status", cfg: {} }, { type: "notifications", cfg: {} }, { type: "visualizer", cfg: {} }, { type: "battery", cfg: { showPercent: Settings.showBattery } }]
		})

	readonly property var current: {
		const l = Settings.barLayout;
		return l && l.v === 1 ? l : defaults;
	}

	function items(zone) {
		return current[zone] || [];
	}

	// config with schema defaults filled in
	function resolve(type, cfg) {
		const out = {};
		const t = types[type];
		if (t)
			for (const f of t.schema)
				out[f.key] = f.def;
		return Object.assign(out, cfg || {});
	}

	function edit(fn) {
		const l = JSON.parse(JSON.stringify(current));
		for (const z of zones)
			l[z] = l[z] || [];
		fn(l);
		l.v = 1;
		Settings.barLayout = l;
	}

	function add(zone, type) {
		edit(l => l[zone].push({ type: type, cfg: {} }));
	}
	function remove(zone, i) {
		edit(l => l[zone].splice(i, 1));
	}
	// move within the zone; returns the new index
	function move(zone, i, delta) {
		const j = i + delta;
		if (j < 0 || j >= items(zone).length)
			return i;
		edit(l => l[zone].splice(j, 0, l[zone].splice(i, 1)[0]));
		return j;
	}
	function moveToZone(zone, i, to) {
		edit(l => l[to].push(l[zone].splice(i, 1)[0]));
		return items(to).length - 1;
	}
	// insert a new item at an exact position
	function insertAt(zone, idx, type) {
		edit(l => l[zone].splice(idx, 0, { type: type, cfg: {} }));
	}
	// move an item to an exact position of another (or the same) zone; idx is the index after removal
	function moveTo(zone, i, to, idx) {
		edit(l => l[to].splice(idx, 0, l[zone].splice(i, 1)[0]));
	}
	function setConfig(zone, i, key, value) {
		edit(l => {
			l[zone][i].cfg = Object.assign({}, l[zone][i].cfg, { [key]: value });
		});
	}
	function reset() {
		Settings.barLayout = {};
	}
}
