import QtQuick
import qs.config

// M3 Expressive slider in the style of end-4/dots-hyprland: the played part is a sine wave
// (flat when `wavy` is off), the rest is a thin rounded track, and the handle is a tall pill
// with a gap to both sides that shrinks while pressed.
Item {
	id: root

	property real value: 0
	property bool wavy: true
	property bool animateWave: true
	property bool interactive: true
	property real waveAmplitude: 3
	property real waveLength: 22
	property real lineWidth: 5
	readonly property bool pressed: mouse.pressed
	readonly property real handleGap: 6

	signal moved(real value)

	implicitHeight: 24

	// phase drifts while the wave is visible; paused or flat bars cost nothing
	property real phase: 0
	NumberAnimation on phase {
		running: root.wavy && root.animateWave && root.visible && root.value > 0
		from: 0
		to: Math.PI * 2
		duration: 1600
		loops: Animation.Infinite
	}
	property real amp: wavy ? waveAmplitude * (pressed ? 0.4 : 1) : 0
	Behavior on amp {
		NumberAnimation {
			duration: Theme.durMedium
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Theme.emphasized
		}
	}

	readonly property real clamped: Math.max(0, Math.min(1, value))
	readonly property real handleX: clamped * (width - handleW) + handleW / 2
	readonly property real handleW: pressed ? 2 : 4

	// remaining track
	Rectangle {
		x: root.handleX + root.handleW / 2 + root.handleGap
		width: Math.max(0, root.width - x)
		height: root.lineWidth
		radius: height / 2
		anchors.verticalCenter: parent.verticalCenter
		color: Theme.surfaceContainerHighest
	}

	// played wave
	Canvas {
		id: wave
		anchors.fill: parent
		renderTarget: Canvas.Image
		onPaint: {
			const ctx = getContext("2d");
			ctx.reset();
			const end = root.handleX - root.handleW / 2 - root.handleGap;
			if (end <= 0)
				return;
			const mid = height / 2;
			ctx.lineWidth = root.lineWidth;
			ctx.lineCap = "round";
			ctx.lineJoin = "round";
			ctx.strokeStyle = Theme.primary;
			ctx.beginPath();
			const k = 2 * Math.PI / root.waveLength;
			for (let x = 0; x <= end; x += 2) {
				// fade the wave in from the left so the cap starts flat
				const f = Math.min(1, x / 12);
				const y = mid + Math.sin(x * k + root.phase) * root.amp * f;
				if (x === 0)
					ctx.moveTo(x + root.lineWidth / 2, y);
				else
					ctx.lineTo(x + root.lineWidth / 2, y);
			}
			ctx.stroke();
		}
		Connections {
			target: root
			function onPhaseChanged() {
				wave.requestPaint();
			}
			function onAmpChanged() {
				wave.requestPaint();
			}
			function onValueChanged() {
				wave.requestPaint();
			}
			function onWidthChanged() {
				wave.requestPaint();
			}
		}
	}

	// handle
	Rectangle {
		x: root.handleX - width / 2
		width: root.handleW
		height: root.pressed ? 22 : 20
		radius: width / 2
		anchors.verticalCenter: parent.verticalCenter
		color: Theme.primary
		Behavior on width {
			NumberAnimation {
				duration: Theme.durShort
			}
		}
		Behavior on height {
			NumberAnimation {
				duration: Theme.durShort
			}
		}
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		enabled: root.interactive
		cursorShape: Qt.PointingHandCursor
		function at(m) {
			return Math.max(0, Math.min(1, m.x / width));
		}
		onPressed: m => root.moved(at(m))
		onPositionChanged: m => {
			if (pressed)
				root.moved(at(m));
		}
	}
}
