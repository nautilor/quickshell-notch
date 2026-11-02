pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wallpaper picker (images from ~/Pictures/Wallpapers, set with awww) and, optionally,
// a colour palette derived from the chosen image (needs ImageMagick).
Singleton {
	id: root

	readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
	// [{path, name, folder}] folder = first sub-directory under dir, "" for files directly inside it
	property var files: []
	readonly property var folders: Array.from(new Set(files.map(f => f.folder).filter(f => f !== ""))).sort()
	property string folderFilter: ""
	readonly property var filtered: folderFilter === "" ? files : files.filter(f => f.folder === folderFilter)
	// palette of Theme roles generated from Settings.wallpaper, or null
	property var pixels: []
	readonly property var palette: pixels.length > 0 ? paletteFrom(pixels, Settings.wallpaperTintBg) : null

	function reload() {
		if (!scan.running)
			scan.running = true;
	}

	function apply(path) {
		Settings.wallpaper = path;
		show(path);
		if (Settings.wallpaperColors)
			extract(path);
	}

	function show(path) {
		Quickshell.execDetached(["sh", "-c", 'command -v awww >/dev/null || exit 1; pgrep -x awww-daemon >/dev/null || { awww-daemon & disown; sleep 0.4; }; awww img "$1" --transition-type=fade --transition-duration=0.5', "sh", path]);
	}

	// ---- colours ----
	property string pending: ""
	property string started: ""

	function extract(path) {
		pending = path;
		if (!magick.running) {
			started = path;
			magick.running = true;
		}
	}

	function hueDist(a, b) {
		const d = Math.abs(a - b) % 1;
		return Math.min(d, 1 - d);
	}

	// pixels: ["#rrggbb", ...]  ->  palette for Colorschemes.build
	function paletteFrom(pixels, tintBg) {
		const BINS = 24;
		const bins = [];
		for (let i = 0; i < BINS; i++)
			bins.push({ w: 0, s: 0, sin: 0, cos: 0 });
		let total = 0;
		for (const px of pixels) {
			const c = Qt.color(px);
			const l = c.hslLightness;
			const s = c.hslSaturation;
			if (c.hslHue < 0 || l < 0.08 || l > 0.95)
				continue;
			const w = s * (1 - Math.abs(2 * l - 1));
			const b = bins[Math.min(BINS - 1, Math.floor(c.hslHue * BINS))];
			b.w += w;
			b.s += s * w;
			b.sin += Math.sin(c.hslHue * 2 * Math.PI) * w;
			b.cos += Math.cos(c.hslHue * 2 * Math.PI) * w;
			total += w;
		}
		const hueOf = b => ((Math.atan2(b.sin, b.cos) / (2 * Math.PI)) + 1) % 1;
		// strongest hues that are not neighbours of one another
		const picks = [];
		const order = bins.map((b, i) => i).sort((x, y) => bins[y].w - bins[x].w);
		for (const i of order) {
			if (bins[i].w <= 0 || picks.length >= 3)
				break;
			if (picks.every(p => hueDist(hueOf(bins[i]), hueOf(bins[p])) > 0.1))
				picks.push(i);
		}
		const grey = pixels.length === 0 || total / pixels.length < 0.03 || picks.length === 0;
		const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
		const h1 = grey ? 0.6 : hueOf(bins[picks[0]]);
		const s1 = grey ? 0.05 : bins[picks[0]].s / bins[picks[0]].w;
		const sat = grey ? 0.06 : clamp(s1, 0.4, 0.8);
		const h2 = picks.length > 1 ? hueOf(bins[picks[1]]) : (h1 + 0.04) % 1;
		const h3 = picks.length > 2 ? hueOf(bins[picks[2]]) : (h1 + 0.16) % 1;
		const col = (h, s, l) => String(Qt.hsla(h, s, l, 1));
		// near-black background, or a dark shade of the wallpaper's own colour
		const tint = grey ? 0.04 : tintBg ? clamp(s1 * 0.6, 0.18, 0.45) : Math.min(0.22, s1 * 0.4);
		const bgL = tintBg ? 0.13 : 0.06;
		const notchL = tintBg ? 0.09 : 0.035;
		return Colorschemes.build("wallpaper", {
			name: "Wallpaper",
			background: col(h1, tint, bgL),
			notch: col(h1, tint * 0.8, notchL),
			foreground: col(h1, grey ? 0.03 : 0.1, 0.92),
			primary: col(h1, sat, 0.74),
			secondary: col(h2, grey ? 0.05 : clamp(sat * 0.7, 0.3, 0.6), 0.72),
			tertiary: col(h3, grey ? 0.05 : clamp(sat * 0.8, 0.35, 0.7), 0.74)
		}).palette;
	}

	Component.onCompleted: {
		if (Settings.wallpaper !== "" && Settings.wallpaperColors)
			extract(Settings.wallpaper);
		if (Settings.wallpaper !== "")
			restore.start();
	}

	// let the session's own wallpaper setup run first
	Timer {
		id: restore
		interval: 2000
		onTriggered: root.show(Settings.wallpaper)
	}

	Connections {
		target: Settings
		function onWallpaperColorsChanged() {
			if (Settings.wallpaperColors && Settings.wallpaper !== "")
				root.extract(Settings.wallpaper);
		}
	}

	Process {
		id: magick
		command: ["sh", "-c", 'f="$1[0]"; magick "$f" -resize 48x48! -alpha off -depth 8 txt:- 2>/dev/null || convert "$f" -resize 48x48! -alpha off -depth 8 txt:-', "sh", root.pending]
		stdout: StdioCollector {
			onStreamFinished: {
				const pixels = [];
				for (const line of text.split("\n")) {
					const m = line.match(/^\d+,\d+:.*?(#[0-9A-Fa-f]{6})/);
					if (m)
						pixels.push(m[1]);
				}
				if (pixels.length > 0)
					root.pixels = pixels;
			}
		}
		onExited: {
			// the wallpaper changed while this one was being read
			if (root.pending !== root.started) {
				root.started = root.pending;
				running = true;
			}
		}
	}

	Process {
		id: scan
		running: true
		command: ["sh", "-c", 'mkdir -p "$1"; find -L "$1" -type f \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" \\) | sort', "sh", root.dir]
		stdout: StdioCollector {
			onStreamFinished: {
				const out = [];
				for (const path of text.split("\n")) {
					if (path === "")
						continue;
					const rel = path.slice(root.dir.length + 1);
					const slash = rel.indexOf("/");
					out.push({ path: path, name: rel.slice(rel.lastIndexOf("/") + 1).replace(/\.[^.]*$/, ""), folder: slash < 0 ? "" : rel.slice(0, slash) });
				}
				root.files = out;
			}
		}
	}
}
