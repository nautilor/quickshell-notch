pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Optional matugen integration (Settings.matugen): whenever the theme source changes, run matugen so
// the templates in ~/.config/matugen/config.toml follow the shell.
//   wallpaper + "Match colours to wallpaper"  ->  matugen image <path> --prefer saturation -m dark
//   colour scheme                             ->  matugen color hex <scheme accent (picked, else primary)> -m dark, with the scheme's own surface/text colours patched in (scripts/matugen-scheme.py)
//   accent                                    ->  matugen color hex <accent> -m dark
Singleton {
	id: root

	// matugen roles taken straight from the colour scheme, so surfaces and text keep its colours
	// instead of being tinted by the accent
	readonly property var schemeRoles: {
		const p = Colorschemes.palette;
		const m = {
			background: p.notch,
			surface: p.notch,
			surface_dim: p.notch,
			surface_container_lowest: p.notch,
			surface_container_low: p.surfaceContainerLow,
			surface_container: p.surfaceContainer,
			surface_container_high: p.surfaceContainerHigh,
			surface_container_highest: p.surfaceContainerHighest,
			surface_bright: p.surfaceContainerHighest,
			surface_variant: p.surfaceContainerHigh,
			on_background: p.surfaceFg,
			on_surface: p.surfaceFg,
			on_surface_variant: p.surfaceVariantFg,
			outline: p.outline,
			outline_variant: p.outlineVariant,
			secondary: p.secondaryContainerFg,
			secondary_container: p.secondaryContainer,
			on_secondary_container: p.secondaryContainerFg,
			tertiary: p.tertiary,
			on_tertiary: p.tertiaryFg,
			tertiary_container: p.tertiaryContainer,
			on_tertiary_container: p.tertiaryContainerFg,
			error: p.error,
			on_error: p.errorFg
		};
		for (const k in m)
			m[k] = String(m[k]);
		return m;
	}

	readonly property var args: {
		if (!Settings.matugen)
			return null;
		if (Settings.wallpaperColors && Settings.wallpaper !== "")
			return ["image", Settings.wallpaper, "--prefer", "saturation"];
		if (Colorschemes.current)
			return [Quickshell.shellDir + "/scripts/matugen-scheme.py", String(Colorschemes.palette.primary), JSON.stringify(schemeRoles)];
		return ["color", "hex", String(Qt.hsla(Settings.hue, 0.55, 0.62, 1))];
	}
	readonly property string key: args ? args.join(" ") : ""

	onKeyChanged: if (key !== "")
		debounce.restart()

	// never two runs at once: matugen's post-hooks share output directories and race each other
	property bool queued: false

	function run() {
		if (!args)
			return;
		if (proc.running) {
			queued = true;
			return;
		}
		proc.command = args[0].endsWith(".py") ? args : ["matugen"].concat(args, ["-m", "dark"]);
		proc.running = true;
	}

	Timer {
		id: debounce
		interval: 400
		onTriggered: root.run()
	}

	Process {
		id: proc
		onExited: if (root.queued) {
			root.queued = false;
			root.run();
		}
		stderr: StdioCollector {
			onStreamFinished: if (text.trim() !== "")
				console.warn("matugen: " + text.trim())
		}
	}
}
