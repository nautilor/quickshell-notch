pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config

// Dock model: pinned apps + running windows, and the freedesktop trash.
Singleton {
	id: root

	readonly property string trashDir: Quickshell.env("HOME") + "/.local/share/Trash"
	readonly property var pinned: Settings.dockPinned || []
	// [{type: "app", key, name, icon, entry, pinned, windows}, {type: "sep"}, {type: "add"}, {type: "trash"}]
	readonly property var items: build(ToplevelManager.toplevels.values, pinned, DesktopEntries.applications.values.length, userDirs)
	property int trashCount: 0

	function entryFor(appId) {
		if (!appId)
			return null;
		return DesktopEntries.byId(appId) ?? DesktopEntries.byId(appId.toLowerCase()) ?? DesktopEntries.heuristicLookup(appId) ?? null;
	}

	// icon-theme name for a folder: XDG user dirs (read from user-dirs.dirs, so localized names work), then plain names
	property var userDirs: ({})
	readonly property var xdgIcons: ({
		"DESKTOP": "user-desktop",
		"DOCUMENTS": "folder-documents",
		"DOWNLOAD": "folder-download",
		"MUSIC": "folder-music",
		"PICTURES": "folder-pictures",
		"PUBLICSHARE": "folder-publicshare",
		"TEMPLATES": "folder-templates",
		"VIDEOS": "folder-videos"
	})
	readonly property var nameIcons: ({
		"desktop": "user-desktop",
		"documents": "folder-documents",
		"downloads": "folder-download",
		"music": "folder-music",
		"pictures": "folder-pictures",
		"videos": "folder-videos",
		"templates": "folder-templates",
		"public": "folder-publicshare",
		"projects": "folder-development",
		"code": "folder-code",
		"dev": "folder-development",
		"src": "folder-code",
		"sources": "folder-code"
	})
	function folderIcon(path, dirs) {
		const clean = path.replace(/(.)\/+$/, "$1");
		if (clean === Quickshell.env("HOME"))
			return "user-home";
		if (dirs && dirs[clean])
			return dirs[clean];
		return nameIcons[clean.split("/").pop().toLowerCase()] ?? "folder";
	}

	function build(toplevels, pins, count, dirs) {
		const groups = {};
		const order = [];
		for (const t of toplevels) {
			const e = entryFor(t.appId);
			const key = e ? e.id : (t.appId || t.title || "?");
			if (!groups[key]) {
				groups[key] = { entry: e, appId: t.appId, windows: [] };
				order.push(key);
			}
			groups[key].windows.push(t);
		}
		const out = [];
		for (const id of pins) {
			if (id.startsWith("dir:")) {
				const path = id.slice(4);
				out.push({ type: "folder", key: id, path: path, name: path.replace(/\/+$/, "").split("/").pop() || "/", icon: folderIcon(path, dirs), entry: null, pinned: true, windows: [] });
				continue;
			}
			const e = DesktopEntries.byId(id);
			if (!e)
				continue;
			out.push({ type: "app", key: id, name: e.name, icon: e.icon, entry: e, pinned: true, windows: groups[id] ? groups[id].windows : [] });
		}
		for (const key of order) {
			if (pins.indexOf(key) >= 0)
				continue;
			const g = groups[key];
			out.push({ type: "app", key: key, name: g.entry ? g.entry.name : (g.appId || key), icon: g.entry ? g.entry.icon : (g.appId || "").toLowerCase(), entry: g.entry, pinned: false, windows: g.windows });
		}
		if (out.length > 0)
			out.push({ type: "sep" });
		out.push({ type: "add" });
		out.push({ type: "trash" });
		return out;
	}

	// ---- window thumbnails ----
	// Hyprland's scrolling layout doesn't render off-screen columns, so those windows can't be captured live.
	// The last good frame of every window we managed to capture is kept here (toplevel -> grab result).
	property var thumbs: new Map()
	property int thumbRev: 0

	function setThumb(tl, res) {
		if (tl && res) {
			thumbs.set(tl, res);
			thumbRev++;
		}
	}
	// pass thumbRev from the binding so it re-evaluates when a thumbnail changes
	function thumbUrl(tl, rev) {
		const r = thumbs.get(tl);
		return r ? r.url : "";
	}

	Connections {
		target: ToplevelManager.toplevels
		function onValuesChanged() {
			const alive = new Set(ToplevelManager.toplevels.values);
			for (const k of Array.from(root.thumbs.keys()))
				if (!alive.has(k))
					root.thumbs.delete(k);
		}
	}

	// ---- apps ----
	property var cycle: ({})

	function activate(item) {
		if (item.windows.length === 0) {
			if (item.entry)
				Apps.launch(item.entry);
			return;
		}
		const i = ((root.cycle[item.key] ?? -1) + 1) % item.windows.length;
		root.cycle[item.key] = i;
		item.windows[i].activate();
	}

	function launch(entry) {
		if (entry)
			Apps.launch(entry);
	}

	function focus(win) {
		win.activate();
	}

	function closeAll(windows) {
		for (const w of windows)
			w.close();
	}

	function hasCustomIcon(key) {
		return !!(Settings.dockIcons || {})[key];
	}

	// custom icon (theme name or image path) if set, else the app's own
	function iconSource(key, fallbackName) {
		const custom = (Settings.dockIcons || {})[key];
		if (custom) {
			if (custom.startsWith("file://") || custom.startsWith("/") || custom.startsWith("~"))
				return "file://" + custom.replace(/^file:\/\//, "").replace(/^~/, Quickshell.env("HOME"));
			return Quickshell.iconPath(custom, "application-x-executable");
		}
		return Quickshell.iconPath(fallbackName, "application-x-executable");
	}

	function setIcon(key, value) {
		const icons = Object.assign({}, Settings.dockIcons || {});
		const v = (value || "").trim();
		if (v === "")
			delete icons[key];
		else
			icons[key] = v;
		Settings.dockIcons = icons;
	}

	// move a pinned app to position `target` among the pinned ones
	function move(key, target) {
		const keys = items.filter(i => (i.type === "app" || i.type === "folder") && i.pinned).map(i => i.key);
		const from = keys.indexOf(key);
		if (from < 0)
			return;
		keys.splice(from, 1);
		keys.splice(Math.max(0, Math.min(keys.length, target)), 0, key);
		// pins whose desktop entry is gone stay in the list
		Settings.dockPinned = keys.concat(pinned.filter(p => keys.indexOf(p) < 0));
	}

	function pin(id) {
		if (pinned.indexOf(id) < 0)
			Settings.dockPinned = pinned.concat([id]);
	}

	function pinFolder(path) {
		pin("dir:" + path.replace(/(.)\/+$/, "$1"));
	}

	function openPath(path) {
		Quickshell.execDetached(["xdg-open", path]);
	}

	function unpin(id) {
		Settings.dockPinned = pinned.filter(p => p !== id);
	}

	Process {
		running: true
		command: ["sh", "-c", '. "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" 2>/dev/null; for k in DESKTOP DOCUMENTS DOWNLOAD MUSIC PICTURES PUBLICSHARE TEMPLATES VIDEOS; do eval "d=\\$XDG_${k}_DIR"; echo "$k $d"; done']
		stdout: StdioCollector {
			onStreamFinished: {
				const m = {};
				for (const l of text.split("\n")) {
					const i = l.indexOf(" ");
					if (i > 0 && l.length > i + 1 && root.xdgIcons[l.slice(0, i)])
						m[l.slice(i + 1).replace(/(.)\/+$/, "$1")] = root.xdgIcons[l.slice(0, i)];
				}
				root.userDirs = m;
			}
		}
	}

	// ---- trash ----
	function refreshTrash() {
		countProc.running = true;
	}

	function openTrash() {
		Quickshell.execDetached(["xdg-open", trashDir + "/files"]);
	}

	function emptyTrash() {
		Quickshell.execDetached(["sh", "-c", 'find "$1/files" "$1/info" -mindepth 1 -delete', "sh", trashDir]);
		recount.restart();
	}

	// paths: absolute local paths dropped on the trash
	function trash(paths) {
		const py = [
			"import sys, os, shutil, urllib.parse, datetime",
			"d = os.path.expanduser('~/.local/share/Trash')",
			"os.makedirs(d + '/files', exist_ok=True)",
			"os.makedirs(d + '/info', exist_ok=True)",
			"for p in sys.argv[1:]:",
			"    p = os.path.abspath(p)",
			"    b = os.path.basename(p.rstrip('/'))",
			"    n, i = b, 1",
			"    while os.path.lexists(d + '/files/' + n) or os.path.exists(d + '/info/' + n + '.trashinfo'):",
			"        n = '%s.%d' % (b, i)",
			"        i += 1",
			"    open(d + '/info/' + n + '.trashinfo', 'w').write('[Trash Info]\\nPath=%s\\nDeletionDate=%s\\n' % (urllib.parse.quote(p), datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S')))",
			"    shutil.move(p, d + '/files/' + n)"
		].join("\n");
		Quickshell.execDetached(["python3", "-c", py].concat(paths));
		recount.restart();
	}

	Timer {
		id: recount
		interval: 700
		onTriggered: root.refreshTrash()
	}

	Timer {
		interval: 5000
		running: Settings.dockEnabled
		repeat: true
		triggeredOnStart: true
		onTriggered: root.refreshTrash()
	}

	Process {
		id: countProc
		command: ["sh", "-c", 'ls -A "$1/files" 2>/dev/null | wc -l', "sh", root.trashDir]
		stdout: StdioCollector {
			onStreamFinished: root.trashCount = parseInt(text) || 0
		}
	}
}
