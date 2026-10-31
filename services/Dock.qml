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
	readonly property var items: build(ToplevelManager.toplevels.values, pinned, DesktopEntries.applications.values.length)
	property int trashCount: 0

	function entryFor(appId) {
		if (!appId)
			return null;
		return DesktopEntries.byId(appId) ?? DesktopEntries.byId(appId.toLowerCase()) ?? DesktopEntries.heuristicLookup(appId) ?? null;
	}

	function build(toplevels, pins) {
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

	function pin(id) {
		if (pinned.indexOf(id) < 0)
			Settings.dockPinned = pinned.concat([id]);
	}

	function unpin(id) {
		Settings.dockPinned = pinned.filter(p => p !== id);
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
