pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import qs.services

// State of the centered Wi-Fi / Bluetooth window, plus the NetworkManager bits Quickshell.Networking does not cover
// (saved connections, VPN, hotspot, hidden networks, connection info). Those go through nmcli.
Singleton {
	id: root

	property bool open: false
	// "wifi" | "bluetooth"
	property string page: "wifi"
	// screen the window is shown on ("" = any)
	property string screen: ""

	function show(kind) {
		screen = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
		page = kind === "bluetooth" ? "bluetooth" : "wifi";
		HomeLayout.connect = "";
		NotchCtl.close();
		open = true;
	}
	function close() {
		open = false;
	}
	function toggle(kind) {
		if (open && page === kind)
			close();
		else
			show(kind);
	}

	// ---- helpers ----
	// run a command, merge stderr into stdout, call done(ok, output)
	Component {
		id: runner
		Process {
			id: proc
			property var done
			stdout: StdioCollector {
				onStreamFinished: {
					const i = text.lastIndexOf("::");
					const code = parseInt(text.slice(i + 2));
					if (proc.done)
						proc.done(code === 0, text.slice(0, i).trim());
					proc.destroy();
				}
			}
		}
	}
	function run(cmd, done) {
		const p = runner.createObject(root, {
			command: ["sh", "-c", "\"$@\" 2>&1; echo \"::$?\"", "sh"].concat(cmd),
			done: done
		});
		p.running = true;
	}
	// same, but done also triggers a refresh of the NetworkManager state
	function nm(args, done) {
		run(["nmcli"].concat(args), (ok, out) => {
			if (done)
				done(ok, out);
			refresh();
		});
	}
	function launch(cmd) {
		Quickshell.execDetached(cmd);
	}

	// true when both lists hold the same items in the same order
	function same(a, b) {
		if (a.length !== b.length)
			return false;
		for (let i = 0; i < a.length; i++)
			if (a[i].key !== b[i].key)
				return false;
		return true;
	}

	// nmcli -t: ':' separates fields, '\' escapes ':' and '\'
	function splitT(line) {
		const out = [];
		let cur = "";
		for (let i = 0; i < line.length; i++) {
			const c = line[i];
			if (c === "\\" && i + 1 < line.length)
				cur += line[++i];
			else if (c === ":") {
				out.push(cur);
				cur = "";
			} else
				cur += c;
		}
		out.push(cur);
		return out;
	}

	// ---- Wi-Fi devices and networks (Quickshell.Networking) ----
	readonly property var wifiDevice: {
		const devs = Networking.devices.values;
		for (let i = 0; i < devs.length; i++)
			if (devs[i].type === DeviceType.Wifi)
				return devs[i];
		return null;
	}
	readonly property var wiredDevices: Networking.devices.values.filter(d => d.type === DeviceType.Wired)

	// ---- NetworkManager state (nmcli) ----
	property bool networking: true
	// [{name, uuid, type, autoconnect, active}] of every saved connection
	property var connections: []
	readonly property var vpns: connections.filter(c => c.type === "vpn" || c.type === "wireguard")
	readonly property var saved: connections.filter(c => c.type === "802-11-wireless" || c.type === "802-3-ethernet")
	readonly property bool hotspotActive: connections.some(c => c.name === "Hotspot" && c.active)
	// [{device, type, state, connection, hwaddr, mtu, ip4, ip6, gateway, dns, ssid, signal, rate, channel, security}]
	property var info: []

	function refresh() {
		const script = "nmcli networking; echo '@@@';"
			+ "nmcli -t -f NAME,UUID,TYPE,AUTOCONNECT connection show; echo '@@@';"
			+ "nmcli -t -f UUID connection show --active; echo '@@@';"
			+ "nmcli -t -f GENERAL,IP4,IP6 device show; echo '@@@';"
			+ "nmcli -t -f IN-USE,SSID,SIGNAL,RATE,CHAN,SECURITY device wifi list --rescan no";
		run(["sh", "-c", script], (ok, out) => {
			const parts = [[], [], [], [], []];
			let n = 0;
			for (const line of out.split("\n")) {
				if (line === "@@@")
					n = Math.min(n + 1, 4);
				else
					parts[n].push(line);
			}
			root.networking = (parts[0][0] || "").trim() !== "disabled";

			const active = new Set(parts[2].filter(l => l !== ""));
			root.connections = parts[1].filter(l => l !== "").map(l => {
				const f = splitT(l);
				return { name: f[0], uuid: f[1], type: f[2], autoconnect: f[3] === "yes", active: active.has(f[1]) };
			});

			let wifi = null;
			for (const l of parts[4]) {
				const f = splitT(l);
				if (f[0] === "*")
					wifi = { ssid: f[1], signal: f[2], rate: f[3], channel: f[4], security: f[5] };
			}

			const devs = [];
			let cur = null;
			for (const l of parts[3]) {
				if (l === "") {
					cur = null;
					continue;
				}
				const i = l.indexOf(":");
				const key = l.slice(0, i).replace(/\[\d+\]$/, "");
				const val = l.slice(i + 1).replace(/\\(.)/g, "$1");
				if (key === "GENERAL.DEVICE") {
					cur = { device: val, type: "", state: "", connection: "", hwaddr: "", mtu: "", ip4: [], ip6: [], gateway: "", dns: [] };
					devs.push(cur);
				}
				if (!cur || val === "")
					continue;
				if (key === "GENERAL.TYPE")
					cur.type = val;
				else if (key === "GENERAL.STATE")
					cur.state = val.replace(/^\d+ \((.*)\)$/, "$1");
				else if (key === "GENERAL.CONNECTION")
					cur.connection = val;
				else if (key === "GENERAL.HWADDR")
					cur.hwaddr = val;
				else if (key === "GENERAL.MTU")
					cur.mtu = val;
				else if (key === "IP4.ADDRESS")
					cur.ip4.push(val);
				else if (key === "IP4.GATEWAY")
					cur.gateway = val;
				else if (key === "IP4.DNS")
					cur.dns.push(val);
				else if (key === "IP6.ADDRESS")
					cur.ip6.push(val);
			}
			root.info = devs.filter(d => d.type !== "loopback" && d.type !== "wifi-p2p" && d.state !== "unmanaged").map(d => Object.assign(d, d.type === "wifi" && wifi ? wifi : {}));
		});
	}

	function setNetworking(on) {
		nm(["networking", on ? "on" : "off"]);
	}
	function connectionUp(uuid, done) {
		nm(["connection", "up", "uuid", uuid], done);
	}
	function connectionDown(uuid, done) {
		nm(["connection", "down", "uuid", uuid], done);
	}
	function connectionDelete(uuid) {
		nm(["connection", "delete", "uuid", uuid]);
	}
	function setAutoconnect(uuid, on) {
		nm(["connection", "modify", "uuid", uuid, "connection.autoconnect", on ? "yes" : "no"]);
	}
	function connectHidden(ssid, psk, done) {
		nm(["device", "wifi", "connect", ssid].concat(psk !== "" ? ["password", psk] : [], ["hidden", "yes"]), done);
	}
	function startHotspot(ssid, psk, done) {
		nm(["device", "wifi", "hotspot", "ssid", ssid, "password", psk], done);
	}
	function stopHotspot(done) {
		nm(["connection", "down", "Hotspot"], done);
	}
	function editConnections() {
		launch(["nm-connection-editor"]);
	}

	Timer {
		interval: 4000
		repeat: true
		running: root.open && root.page === "wifi"
		triggeredOnStart: true
		onTriggered: root.refresh()
	}
}
