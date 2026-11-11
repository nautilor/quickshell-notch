pragma Singleton

import Quickshell
import Quickshell.Hyprland

// Hyprland 0.57+ dispatches take Lua (`hl.dsp.*`), the old "workspace 2" strings are rejected.
Singleton {
	// target: workspace id (number) or relative string such as "e-1" / "e+1"
	function focusWorkspace(target) {
		const t = typeof target === "number" ? String(target) : JSON.stringify(target);
		Hyprland.dispatch("hl.dsp.focus({ workspace = " + t + " })");
	}
}
