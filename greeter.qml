import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd
import QtQuick
import qs.config
import qs.services
import qs.components

// Login screen for greetd. Run it inside a Wayland compositor started by greetd:
//   quickshell -p /path/to/quickshell-notch/greeter.qml
// See "Login screen" in the README.
ShellRoot {
	Variants {
		model: Quickshell.screens

		PanelWindow {
			required property var modelData
			screen: modelData

			anchors {
				top: true
				bottom: true
				left: true
				right: true
			}
			color: Theme.notch
			exclusionMode: ExclusionMode.Ignore
			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "notch-greeter"
			WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

			AuthScreen {
				id: auth
				anchors.fill: parent
				wallpaper: GreeterCtl.wallpaper
				avatar: GreeterCtl.avatar
				name: GreeterCtl.fullName
				prompt: GreeterCtl.prompt
				buffer: GreeterCtl.buffer
				busy: GreeterCtl.busy
				error: GreeterCtl.error
				failures: GreeterCtl.failures
				onEdited: text => {
					GreeterCtl.buffer = text;
					GreeterCtl.error = "";
				}
				onSubmitted: GreeterCtl.submit()

				// pick another user, and the session to start
				Row {
					visible: GreeterCtl.users.length > 1
					spacing: 8
					Repeater {
						model: GreeterCtl.users
						Btn {
							required property var modelData
							label: modelData.full || modelData.name
							iconSize: 18
							toggleable: true
							toggled: GreeterCtl.user === modelData.name
							implicitHeight: 36
							onClicked: {
								GreeterCtl.selectUser(modelData.name);
								auth.focusInput();
							}
						}
					}
				}
				Btn {
					visible: GreeterCtl.sessions.length > 1
					icon: "monitor"
					label: GreeterCtl.session.name
					iconSize: 18
					implicitHeight: 36
					variant: 2
					onClicked: GreeterCtl.nextSession()
				}
				Txt {
					visible: !Greetd.available
					text: "greetd is not available. Start this inside greetd."
					color: Theme.error
					font.pixelSize: 12
				}
			}
		}
	}
}
