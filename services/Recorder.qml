pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// Screen recording through wf-recorder, driven by one shell script so a single Stop ends everything.
// Several screens are recorded in parallel and merged into one video with ffmpeg (laid out like the real monitors).
Singleton {
	id: root

	// "screens" | "window"
	property string mode: "screens"
	property var selectedScreens: []
	// {title, cls, geometry, screen} of the window picked in the Record tab
	property var chosenWindow: null
	property bool micAudio: false
	property bool systemAudio: false
	// visible windows: {title, cls, geometry, screen}
	property var windows: []

	property bool recording: false
	// the mic was muted when recording started: unmuted for the recording, muted again afterwards
	property bool micWasMuted: false
	property bool merging: false
	property int elapsed: 0
	property string lastFile: ""
	readonly property string dir: Settings.recordDir !== "" ? Settings.recordDir : Quickshell.env("HOME") + "/Videos/Recordings"
	readonly property bool canStart: mode === "screens" ? selectedScreens.length > 0 : chosenWindow !== null

	function isSelected(name) {
		return selectedScreens.indexOf(name) >= 0;
	}

	function toggleScreen(name) {
		selectedScreens = isSelected(name) ? selectedScreens.filter(n => n !== name) : selectedScreens.concat([name]);
	}

	function selectAll() {
		selectedScreens = Quickshell.screens.map(s => s.name);
	}

	function q(s) {
		return "'" + String(s).replace(/'/g, "'\\''") + "'";
	}

	// parts: [{name, target: ["-o", "eDP-1"] | ["-g", "x,y WxH"], screen?}]
	function begin(parts) {
		if (recording || parts.length === 0)
			return;
		const stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss");
		const multi = parts.length > 1;
		const out = dir + "/rec-" + stamp + (multi ? "-all" : "-" + parts[0].name) + ".mp4";
		const tmp = dir + "/.rec-" + stamp;
		const log = q(dir + "/.recorder.log");
		const sh = [];

		// one audio source on one screen is recorded by wf-recorder itself; anything else is mixed afterwards with ffmpeg
		const direct = !multi && micAudio !== systemAudio;
		const needFfmpeg = multi || (micAudio && systemAudio);
		sh.push("set -f");
		if (needFfmpeg)
			sh.push("command -v ffmpeg >/dev/null && command -v ffprobe >/dev/null || { echo 'error ffmpeg is needed for several screens or mic + system audio'; exit 1; }");
		sh.push("mkdir -p " + q(tmp));
		sh.push("pids=''; apids=''; audio=''; dev=''");
		if (direct)
			sh.push(micAudio ? "dev=$(pactl get-default-source)" : "dev=$(pactl get-default-sink).monitor");
		else if (micAudio)
			// audio is captured as separate wav files and mixed afterwards: loopback mixing in PipeWire crackled
			sh.push("parecord -d \"$(pactl get-default-source)\" --file-format=wav " + q(tmp + "/mic.wav") + " 2>>" + log + " & apids=\"$apids $!\"; audio=\"$audio mic\"");
		// NVIDIA GPUs encode with NVENC (the CPU encoder at 4K is what makes everything lag); falls back to the CPU if it fails to start
		sh.push("enc=''");
		if (Settings.recordEncoder !== "cpu")
			sh.push("[ -e /dev/nvidiactl ] && enc='-c h264_nvenc -p rc=vbr -p cq=23 -p preset=p4'");
		const cmds = parts.map((p, i) => {
			let cmd = "wf-recorder -y -f " + q(tmp + "/" + i + ".mp4") + " " + p.target.map(q).join(" ");
			if (multi)
				cmd += " -r 30";
			if (direct && i === 0)
				cmd += " ${dev:+--audio=$dev}";
			return cmd + " 2>>" + log;
		});
		cmds.forEach((cmd, i) => sh.push(cmd + " $enc & p" + i + "=$!; pids=\"$pids $!\""));
		sh.push("trap 'kill -INT $pids 2>/dev/null' INT TERM");
		if (systemAudio && !direct) {
			// a Bluetooth headset switches profile (and gets a new output node) when the mic opens: let that settle first
			if (micAudio)
				sh.push("sleep 2");
			sh.push("parecord -d \"$(pactl get-default-sink).monitor\" --file-format=wav " + q(tmp + "/sys.wav") + " 2>>" + log + " & apids=\"$apids $!\"; audio=\"$audio sys\"");
		}
		sh.push("if [ -n \"$enc\" ]; then sleep 1; enc=''; pids=''");
		cmds.forEach((cmd, i) => sh.push("kill -0 $p" + i + " 2>/dev/null || { " + cmd + " & p" + i + "=$!; }; pids=\"$pids $p" + i + "\""));
		sh.push("fi");
		sh.push("for p in $pids; do while kill -0 $p 2>/dev/null; do wait $p; done; done");
		sh.push("trap - INT TERM");
		sh.push("[ -n \"$apids\" ] && { kill -TERM $apids 2>/dev/null; wait $apids 2>/dev/null; }");
		// drop audio tracks that captured nothing
		sh.push("keep=''; for a in $audio; do [ \"$(wc -c < " + q(tmp) + "/$a.wav)\" -gt 1000 ] && keep=\"$keep $a\"; done; audio=$keep");

		// ffmpeg inputs: screens first, then the audio files that exist
		const n = parts.length;
		let inputs = "";
		parts.forEach((p, i) => inputs += " -i " + q(tmp + "/" + i + ".mp4"));
		let fc = "";
		let vmap = "-map 0:v -c:v copy";
		if (multi) {
			// layout of the screens in logical pixels, scaled up to the sharpest one
			const scr = parts.map(p => p.screen);
			const f = Math.max(...scr.map(s => s.devicePixelRatio));
			const x0 = Math.min(...scr.map(s => s.x));
			const y0 = Math.min(...scr.map(s => s.y));
			const even = v => 2 * Math.round(v / 2);
			const cw = even(Math.max(...scr.map(s => s.x + s.width)) * f - x0 * f);
			const ch = even(Math.max(...scr.map(s => s.y + s.height)) * f - y0 * f);
			fc = "color=c=black:s=" + cw + "x" + ch + ":r=30[bg0]";
			scr.forEach((s, i) => {
				fc += ";[" + i + ":v]scale=" + even(s.width * f) + ":" + even(s.height * f) + "[v" + i + "]";
				fc += ";[bg" + i + "][v" + i + "]overlay=" + Math.round((s.x - x0) * f) + ":" + Math.round((s.y - y0) * f) + ":shortest=1[bg" + (i + 1) + "]";
			});
			vmap = "-map '[bg" + n + "]' -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p";
		}
		if (needFfmpeg) {
			// audio starts late (devices wake up), so it is padded at the front to end together with the video
			sh.push("vd=$(ffprobe -v error -show_entries format=duration -of csv=p=0 " + q(tmp + "/0.mp4") + " 2>/dev/null)");
			sh.push("ain=''; amap=''; fa=''; k=" + n);
			sh.push("for a in $audio; do ain=\"$ain -i " + tmp + "/$a.wav\"; fa=\"${fa:+$fa;}[$k:a]areverse,apad=whole_dur=$vd,areverse[a$k]\"; k=$((k+1)); done");
			sh.push("na=$(echo $audio | wc -w)");
			sh.push("if [ \"$na\" = 2 ]; then fa=\"$fa;[a" + n + "][a" + (n + 1) + "]amix=inputs=2:normalize=0[aout]\"; amap='-map [aout] -c:a aac -t '$vd");
			sh.push("elif [ \"$na\" = 1 ]; then amap='-map [a" + n + "] -c:a aac -t '$vd; fi");
			sh.push("vf=" + q(fc));
			sh.push("fc=\"$vf${vf:+${fa:+;}}$fa\"");
			sh.push("if [ -n \"$fc\" ]; then fcopt=\"-filter_complex $fc\"; else fcopt=''; fi");
		}
		if (needFfmpeg) {
			sh.push("echo merging");
			sh.push("ffmpeg -y -loglevel error" + inputs + "$ain $fcopt " + vmap + " $amap " + q(out) + " 2>>" + log);
		} else {
			sh.push("mv " + q(tmp + "/0.mp4") + " " + q(out));
		}
		sh.push("[ -f " + q(out) + " ] && rm -rf " + q(tmp));
		sh.push("[ -f " + q(out) + " ] || { for f in " + q(tmp) + "/*.mp4; do mv \"$f\" " + q(dir + "/rec-" + stamp + "-part-") + "$(basename \"$f\"); done; rm -rf " + q(tmp) + "; }");
		sh.push("if [ -f " + q(out) + " ]; then echo " + q("saved " + out) + "; else echo 'error nothing was recorded, see .recorder.log'; fi");

		micWasMuted = micAudio && Mic.muted;
		if (micWasMuted)
			Mic.setMuted(false);
		elapsed = 0;
		merging = false;
		lastFile = out;
		recorder.command = ["sh", "-c", sh.join("\n")];
		recording = true;
		recorder.running = true;
		Hud.show("record", "videocam", multi ? "Recording " + parts.length + " screens" : "Recording", true);
	}

	function startScreens(names) {
		const screens = Quickshell.screens.filter(s => names.indexOf(s.name) >= 0);
		begin(screens.map(s => ({ name: s.name, target: ["-o", s.name], screen: s })));
	}

	function startWindow(w) {
		begin([{ name: "window", target: ["-g", w.geometry] }]);
	}

	// record with what the Record tab has selected
	function start() {
		if (mode === "screens")
			startScreens(selectedScreens);
		else if (chosenWindow)
			startWindow(chosenWindow);
	}

	function stop() {
		if (recording && !merging)
			recorder.signal(15);
	}

	function toggle() {
		if (recording)
			stop();
		else
			start();
	}

	function refreshWindows() {
		lister.running = true;
	}

	Process {
		id: recorder
		stdout: SplitParser {
			onRead: line => {
				if (line === "merging") {
					root.merging = true;
					Hud.show("record", "videocam", "Merging screens…", false, 60000);
				} else if (line.startsWith("saved ")) {
					root.lastFile = line.slice(6);
					Hud.show("record", "videocam", "Saved " + root.lastFile.split("/").pop(), false, 4000);
				} else if (line.startsWith("error ")) {
					Hud.show("record", "videocam", line.slice(6), true, 5000);
				}
			}
		}
		onExited: {
			root.recording = false;
			root.merging = false;
			if (root.micWasMuted)
				Mic.setMuted(true);
			root.micWasMuted = false;
		}
	}

	// windows on the workspaces currently shown, in the global coordinates wf-recorder expects
	Process {
		id: lister
		command: ["sh", "-c", "hyprctl monitors -j; echo '#####'; hyprctl clients -j"]
		stdout: StdioCollector {
			id: listOut
		}
		onExited: {
			const parts = listOut.text.split("#####");
			if (parts.length < 2)
				return;
			try {
				const monitors = JSON.parse(parts[0]);
				const shown = {};
				for (const m of monitors)
					shown[m.activeWorkspace.id] = m.name;
				root.windows = JSON.parse(parts[1]).filter(c => c.mapped && !c.hidden && shown[c.workspace.id] !== undefined).map(c => ({
							title: c.title,
							cls: c.class,
							screen: shown[c.workspace.id],
							geometry: c.at[0] + "," + c.at[1] + " " + c.size[0] + "x" + c.size[1]
						}));
			} catch (e) {
				root.windows = [];
			}
		}
	}

	Timer {
		interval: 1000
		running: root.recording && !root.merging
		repeat: true
		onTriggered: root.elapsed++
	}
}
