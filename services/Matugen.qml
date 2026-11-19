pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Optional matugen integration (Settings.matugen): whenever the theme source changes, run matugen so
// the templates in ~/.config/matugen/config.toml follow the shell.
//   wallpaper + "Match colours to wallpaper"  ->  matugen image <path> --prefer saturation -m dark
//   colour scheme                             ->  matugen color hex <scheme primary> -m dark
//   accent                                    ->  matugen color hex <accent> -m dark
Singleton {
	id: root

	readonly property var args: {
		if (!Settings.matugen)
			return null;
		if (Settings.wallpaperColors && Settings.wallpaper !== "")
			return ["image", Settings.wallpaper, "--prefer", "saturation"];
		const scheme = Colorschemes.current;
		if (scheme)
			return ["color", "hex", String(scheme.palette.primary)];
		return ["color", "hex", String(Qt.hsla(Settings.hue, 0.55, 0.62, 1))];
	}
	readonly property string key: args ? args.join(" ") : ""

	onKeyChanged: if (key !== "")
		debounce.restart()

	Timer {
		id: debounce
		interval: 400
		onTriggered: {
			if (!root.args)
				return;
			proc.command = ["matugen"].concat(root.args, ["-m", "dark"]);
			proc.running = false;
			proc.running = true;
		}
	}

	Process {
		id: proc
		stderr: StdioCollector {
			onStreamFinished: if (text.trim() !== "")
				console.warn("matugen: " + text.trim())
		}
	}
}
