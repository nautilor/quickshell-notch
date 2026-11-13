pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Named snapshots of the settings, stored in ~/.config/quickshell-notch/presets.json.
// Saving captures every key in `keys`; applying writes them back to Settings.
Singleton {
	id: root

	// settings a preset covers; runtime state (dnd, launchCounts) is left out
	readonly property var keys: ["hue", "colorscheme", "uiStyle", "surfaceOpacity", "builtinLock", "lockPam", "lockPamDir", "lockWallpaper", "lockAvatar", "hoverOpen", "homeLayout", "homeStyle", "homeOnHover", "screenCorners", "cornerRadius", "autohide", "fullBar", "barLayout", "barHeight", "notifTimeout", "weekStartsMonday", "use24h", "showClock", "showDate", "showBattery", "showDateHome", "caffeineOnMessage", "caffeineOffMessage", "micOnMessage", "micOffMessage", "notchEdge", "notchAlign", "placements", "dockEnabled", "dockEdge", "dockAutohide", "dockAllScreens", "dockIconSize", "dockPinned", "dockIcons", "wallpaper", "wallpaperColors", "wallpaperTintBg", "recordDir", "recordEncoder"]

	// {name: {key: value}}
	readonly property var all: store.presets || ({})
	readonly property var names: Object.keys(all).sort((a, b) => a.localeCompare(b))
	readonly property string active: store.active

	function snapshot() {
		const out = {};
		for (const k of keys)
			out[k] = JSON.parse(JSON.stringify(Settings[k] === undefined ? null : Settings[k]));
		return out;
	}

	// create or overwrite
	function save(name) {
		name = (name || "").trim();
		if (name === "")
			return false;
		const m = Object.assign({}, all);
		m[name] = snapshot();
		store.presets = m;
		store.active = name;
		return true;
	}

	function apply(name) {
		const p = all[name];
		if (!p)
			return;
		for (const k of keys) {
			if (p[k] !== undefined)
				Settings[k] = JSON.parse(JSON.stringify(p[k]));
		}
		store.active = name;
	}

	function remove(name) {
		const m = Object.assign({}, all);
		delete m[name];
		store.presets = m;
		if (store.active === name)
			store.active = "";
	}

	function rename(from, to) {
		to = (to || "").trim();
		if (to === "" || to === from || !all[from] || all[to])
			return false;
		const m = {};
		for (const n of Object.keys(all))
			m[n === from ? to : n] = all[n];
		store.presets = m;
		if (store.active === from)
			store.active = to;
		return true;
	}

	FileView {
		path: Settings.dirReady ? Settings.configDir + "/presets.json" : ""
		watchChanges: true
		onFileChanged: reload()
		onAdapterUpdated: writeAdapter()
		onLoadFailed: error => {
			if (error === FileViewError.FileNotFound)
				writeAdapter();
		}

		adapter: JsonAdapter {
			id: store
			property var presets: ({})
			// name of the preset applied or saved last
			property string active: ""
		}
	}
}
