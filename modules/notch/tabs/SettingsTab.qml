import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

Item {
	id: root

	property int page: 0
	readonly property var pages: [{ name: "Appearance", icon: "brightness_7" }, { name: "Notch", icon: "tune" }, { name: "Notifications", icon: "notifications" }, { name: "Date & time", icon: "schedule" }, { name: "Calendar", icon: "calendar_month" }, { name: "Dock", icon: "apps" }, { name: "Wallpaper", icon: "image" }, { name: "Placement", icon: "place" }]

	Component.onCompleted: {
		Colorschemes.reload();
		Wallpaper.reload();
	}

	// left pane: category list
	Column {
		id: sidebar
		anchors.left: parent.left
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		width: 160
		spacing: 4
		Repeater {
			model: root.pages
			Rectangle {
				id: navItem
				required property var modelData
				required property int index
				readonly property bool current: root.page === index
				width: sidebar.width
				height: 44
				radius: current ? Theme.radiusSmall : Theme.radiusMedium
				color: current ? Theme.primaryContainer : navArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
				Behavior on radius {
					NumberAnimation {
						duration: Theme.durShort
					}
				}
				Row {
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					anchors.leftMargin: 14
					spacing: 10
					Icon {
						name: navItem.modelData.icon
						size: 20
						anchors.verticalCenter: parent.verticalCenter
						color: navItem.current ? Theme.primaryContainerFg : Theme.surfaceVariantFg
					}
					Txt {
						text: navItem.modelData.name
						anchors.verticalCenter: parent.verticalCenter
						font.weight: navItem.current ? Font.Medium : Font.Normal
						color: navItem.current ? Theme.primaryContainerFg : Theme.surfaceFg
					}
				}
				MouseArea {
					id: navArea
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: root.page = navItem.index
				}
			}
		}
	}

	Rectangle {
		id: divider
		anchors.left: sidebar.right
		anchors.leftMargin: 8
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		width: 1
		color: Theme.outlineVariant
	}

	// right pane: selected category
	Flickable {
		id: flick
		anchors.left: divider.right
		anchors.leftMargin: 12
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		contentHeight: col.implicitHeight + 8
		clip: true
		boundsBehavior: Flickable.StopAtBounds

		Connections {
			target: root
			function onPageChanged() {
				flick.contentY = 0;
			}
		}

		ColumnLayout {
			id: col
			width: flick.width - 12
			spacing: 8

			ColumnLayout {
				Layout.fillWidth: true
				visible: root.page === 0
				spacing: 8

				SectionLabel {
					text: "APPEARANCE"
				}
				Item {
					id: accentWrap
					readonly property bool shown: Settings.colorscheme === "" && !Settings.wallpaperColors
					property real amount: shown ? 1 : 0
					Behavior on amount {
						NumberAnimation {
							duration: Theme.durMedium
							easing.type: Easing.OutCubic
						}
					}
					Layout.fillWidth: true
					Layout.preferredHeight: accentRow.implicitHeight * amount
					Layout.bottomMargin: -col.spacing * (1 - amount)
					visible: amount > 0
					clip: true
					opacity: amount
					SettingRow {
						id: accentRow
						width: parent.width
						y: -8 * (1 - accentWrap.amount)
						title: "Accent colour"
						subtitle: "Seed for the Material tonal palette"
						Repeater {
							model: [0.53, 0.6, 0.75, 0.92, 0.04, 0.12, 0.35]
							// fixed-size cell so the row never reflows while a swatch animates
							Item {
								id: cell
								required property real modelData
								readonly property bool current: Math.abs(Settings.hue - modelData) < 0.01
								Layout.preferredWidth: 36
								Layout.preferredHeight: 36
								Rectangle {
									anchors.centerIn: parent
									width: cell.current ? 32 : 26
									height: width
									radius: cell.current ? 11 : width / 2
									color: Qt.hsla(cell.modelData, 0.55, 0.62, 1)
									border.width: cell.current ? 3 : 0
									border.color: Theme.surfaceFg
									Behavior on width {
										NumberAnimation {
											duration: Theme.durShort
											easing.type: Easing.OutBack
										}
									}
									Behavior on radius {
										NumberAnimation {
											duration: Theme.durShort
										}
									}
								}
								MouseArea {
									anchors.fill: parent
									cursorShape: Qt.PointingHandCursor
									onClicked: Settings.hue = cell.modelData
								}
							}
						}
					}
				}
				SettingRow {
					title: "Colour scheme"
					subtitle: (Colorschemes.current ? Colorschemes.current.name : "Accent") + " · your own .json files go in ~/.config/quickshell-notch/colorschemes/"
					Btn {
						icon: "chevron_right"
						implicitWidth: 40
						implicitHeight: 40
						rotation: schemeWrap.expanded ? 270 : 90
						Behavior on rotation {
							NumberAnimation {
								duration: Theme.durMedium
								easing.type: Easing.OutCubic
							}
						}
						onClicked: schemeWrap.expanded = !schemeWrap.expanded
					}
				}
				Item {
					id: schemeWrap
					property bool expanded: false
					Layout.fillWidth: true
					Layout.preferredHeight: expanded ? schemeFlow.implicitHeight : 54
					clip: true
					Behavior on Layout.preferredHeight {
						NumberAnimation {
							duration: Theme.durMedium
							easing.type: Easing.OutCubic
						}
					}
					Flow {
						id: schemeFlow
						width: parent.width
						spacing: 8
						Repeater {
							model: [{
									id: "",
									name: "Accent",
									preview: [Theme.tone(0.18, 0.15), Qt.hsla(Settings.hue, 0.55, 0.76, 1), Qt.hsla((Settings.hue + 0.02) % 1, 0.35, 0.88, 1), Qt.hsla((Settings.hue + 0.16) % 1, 0.5, 0.79, 1)]
								}].concat(Colorschemes.schemes)
							Rectangle {
								id: chip
								required property var modelData
								readonly property bool current: Settings.colorscheme === modelData.id
								width: 150
								height: 54
								radius: current ? Theme.radiusSmall : Theme.radiusMedium
								color: current ? Theme.primaryContainer : Theme.surfaceContainerHigh
								Behavior on radius {
									NumberAnimation {
										duration: Theme.durShort
									}
								}
								Row {
									anchors.left: parent.left
									anchors.leftMargin: 12
									anchors.top: parent.top
									anchors.topMargin: 10
									spacing: 4
									Repeater {
										model: chip.modelData.preview
										Rectangle {
											required property color modelData
											width: 14
											height: 14
											radius: 7
											color: modelData
											border.width: 1
											border.color: Theme.outlineVariant
										}
									}
								}
								Txt {
									anchors.left: parent.left
									anchors.right: parent.right
									anchors.bottom: parent.bottom
									anchors.margins: 12
									anchors.bottomMargin: 8
									text: chip.modelData.name
									font.pixelSize: 12
									color: chip.current ? Theme.primaryContainerFg : Theme.surfaceVariantFg
								}
								MouseArea {
									anchors.fill: parent
									cursorShape: Qt.PointingHandCursor
									onClicked: Settings.colorscheme = chip.modelData.id
								}
							}
						}
					}
				}
				SettingRow {
					title: "Home layout"
					subtitle: "Grid is editable; the others are fixed. All keep Wi-Fi, Bluetooth, power profile, tray and next event"
				}
				Flow {
					Layout.fillWidth: true
					spacing: 8
					Repeater {
						model: HomeStyles.list
						Rectangle {
							id: styleChip
							required property var modelData
							readonly property bool current: Settings.homeStyle === modelData.id
							width: 150
							height: 54
							radius: current ? Theme.radiusSmall : Theme.radiusMedium
							color: current ? Theme.primaryContainer : Theme.surfaceContainerHigh
							Behavior on radius {
								NumberAnimation {
									duration: Theme.durShort
								}
							}
							Row {
								anchors.centerIn: parent
								spacing: 8
								Icon {
									name: styleChip.modelData.icon
									size: 20
									anchors.verticalCenter: parent.verticalCenter
									color: styleChip.current ? Theme.primaryContainerFg : Theme.surfaceVariantFg
								}
								Txt {
									text: styleChip.modelData.name
									anchors.verticalCenter: parent.verticalCenter
									elide: Text.ElideNone
									font.pixelSize: 12
									color: styleChip.current ? Theme.primaryContainerFg : Theme.surfaceVariantFg
								}
							}
							MouseArea {
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									HomeLayout.editing = false;
									Settings.homeStyle = styleChip.modelData.id;
								}
							}
						}
					}
				}
				SettingRow {
					title: "Rounded screen corners"
					subtitle: "Round every corner of every screen"
					Switch {
						checked: Settings.screenCorners
						onToggled: v => Settings.screenCorners = v
					}
				}
				SettingRow {
					title: "Date on Home tab"
					subtitle: "Show the date next to the clock in the header"
					Switch {
						checked: Settings.showDateHome
						onToggled: v => Settings.showDateHome = v
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				visible: root.page === 1
				spacing: 8

				SectionLabel {
					text: "NOTCH"
				}
				SettingRow {
					title: "Open on hover"
					subtitle: "Otherwise click the notch or use IPC"
					Switch {
						checked: Settings.hoverOpen
						onToggled: v => Settings.hoverOpen = v
					}
				}
				SettingRow {
					title: "Home on hover"
					subtitle: "Hovering the notch always opens the Home tab"
					Switch {
						checked: Settings.homeOnHover
						onToggled: v => Settings.homeOnHover = v
					}
				}
				SettingRow {
					title: "Autohide"
					subtitle: "Slide the idle notch off screen; hover the top edge to bring it back"
					Switch {
						checked: Settings.autohide
						onToggled: v => Settings.autohide = v
					}
				}
				SettingRow {
					title: "Show on all screens"
					subtitle: "Otherwise only on the first screen"
					Switch {
						checked: Settings.allScreens
						onToggled: v => Settings.allScreens = v
					}
				}
				SettingRow {
					title: "Clock on closed notch"
					subtitle: "Show the time in the middle while idle"
					Switch {
						checked: Settings.showClock
						onToggled: v => Settings.showClock = v
					}
				}
				SettingRow {
					title: "Date on closed notch"
					subtitle: "Show the date in the middle while idle"
					Switch {
						checked: Settings.showDate
						onToggled: v => Settings.showDate = v
					}
				}
				SettingRow {
					title: "Battery on closed notch"
					subtitle: "Show the battery percentage while idle"
					Switch {
						checked: Settings.showBattery
						onToggled: v => Settings.showBattery = v
					}
				}
				SettingRow {
					title: "Built-in lock screen"
					subtitle: "Lock button uses this instead of hyprlock"
					Switch {
						checked: Settings.builtinLock
						onToggled: v => Settings.builtinLock = v
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				visible: root.page === 2
				spacing: 8

				SectionLabel {
					text: "NOTIFICATIONS"
				}
				SettingRow {
					title: "Do not disturb"
					subtitle: "Notifications are kept, but not shown"
					Switch {
						checked: Settings.dnd
						onToggled: v => Settings.dnd = v
					}
				}
				SettingRow {
					title: "Notification time"
					subtitle: (Settings.notifTimeout / 1000) + " seconds on the notch"
					Btn {
						icon: "remove"
						implicitWidth: 40
						implicitHeight: 40
						onClicked: Settings.notifTimeout = Math.max(2000, Settings.notifTimeout - 1000)
					}
					Btn {
						icon: "add"
						implicitWidth: 40
						implicitHeight: 40
						onClicked: Settings.notifTimeout = Math.min(30000, Settings.notifTimeout + 1000)
					}
				}
				SettingRow {
					title: "Caffeine on"
					Field {
						implicitWidth: 300
						text: Settings.caffeineOnMessage
						onEdited: v => Settings.caffeineOnMessage = v
					}
				}
				SettingRow {
					title: "Caffeine off"
					Field {
						implicitWidth: 300
						text: Settings.caffeineOffMessage
						onEdited: v => Settings.caffeineOffMessage = v
					}
				}
				SettingRow {
					title: "Microphone live"
					Field {
						implicitWidth: 300
						text: Settings.micOnMessage
						onEdited: v => Settings.micOnMessage = v
					}
				}
				SettingRow {
					title: "Microphone muted"
					Field {
						implicitWidth: 300
						text: Settings.micOffMessage
						onEdited: v => Settings.micOffMessage = v
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				visible: root.page === 3
				spacing: 8

				SectionLabel {
					text: "DATE & TIME"
				}
				SettingRow {
					title: "24-hour clock"
					Switch {
						checked: Settings.use24h
						onToggled: v => Settings.use24h = v
					}
				}
				SettingRow {
					title: "Week starts on Monday"
					Switch {
						checked: Settings.weekStartsMonday
						onToggled: v => {
							Settings.weekStartsMonday = v;
							Gcal.weekStart = Gcal.startOfWeek(Gcal.today);
							Gcal.refresh();
						}
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				visible: root.page === 4
				spacing: 8

				SectionLabel {
					text: "CALENDAR"
				}
				SettingRow {
					title: "Local calendar"
					subtitle: "Always available. Events are stored in ~/.config/quickshell-notch/calendar.json"
				}
				SettingRow {
					title: Gcal.authState === "ready" ? "Google Calendar connected" : "Google Calendar"
					subtitle: Gcal.authState === "ready" ? "Google events are shown next to your local ones" : Gcal.authState === "no-client" ? "Optional. Missing " + Gcal.clientFile : "Optional. Sign in to also show your Google events"
					Btn {
						visible: Gcal.authState === "ready"
						label: "Sign out"
						onClicked: Gcal.logout()
					}
					Btn {
						visible: Gcal.authState === "logged-out"
						label: Gcal.loggingIn ? "Waiting for browser…" : "Sign in"
						variant: 1
						enabled: !Gcal.loggingIn
						onClicked: Gcal.login()
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				visible: root.page === 5
				spacing: 8

				SectionLabel {
					text: "DOCK"
				}
				SettingRow {
					title: "Show dock"
					subtitle: "Pinned and running apps, plus the trash"
					Switch {
						checked: Settings.dockEnabled
						onToggled: v => Settings.dockEnabled = v
					}
				}
				SettingRow {
					title: "Position"
					subtitle: "Screen edge the dock is attached to"
				}
				EdgePicker {
					value: Settings.dockEdge
					onPicked: edge => Settings.dockEdge = edge
				}
				SettingRow {
					title: "Autohide"
					subtitle: "Slide the dock off screen; hover the edge to bring it back. Otherwise it reserves space"
					Switch {
						checked: Settings.dockAutohide
						onToggled: v => Settings.dockAutohide = v
					}
				}
				SettingRow {
					title: "Show on all screens"
					subtitle: "Otherwise only on the first screen"
					Switch {
						checked: Settings.dockAllScreens
						onToggled: v => Settings.dockAllScreens = v
					}
				}
				SettingRow {
					title: "Icon size"
					subtitle: Settings.dockIconSize + " px"
					Btn {
						icon: "remove"
						implicitWidth: 40
						implicitHeight: 40
						onClicked: Settings.dockIconSize = Math.max(28, Settings.dockIconSize - 4)
					}
					Btn {
						icon: "add"
						implicitWidth: 40
						implicitHeight: 40
						onClicked: Settings.dockIconSize = Math.min(72, Settings.dockIconSize + 4)
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				visible: root.page === 6
				spacing: 8

				SectionLabel {
					text: "WALLPAPER"
				}
				SettingRow {
					title: "Match colours to wallpaper"
					subtitle: "Generate the theme from the chosen wallpaper. Replaces the accent and colour scheme"
					Switch {
						checked: Settings.wallpaperColors
						onToggled: v => Settings.wallpaperColors = v
					}
				}
				SettingRow {
					title: "Tint the background"
					subtitle: "Use a dark shade of the wallpaper colour instead of near-black"
					enabled: Settings.wallpaperColors
					opacity: enabled ? 1 : 0.5
					Switch {
						checked: Settings.wallpaperTintBg
						onToggled: v => Settings.wallpaperTintBg = v
					}
				}
				SettingRow {
					title: "Wallpaper folder"
					subtitle: "~/Pictures/Wallpapers · " + Wallpaper.files.length + " images"
					Btn {
						icon: "refresh"
						implicitWidth: 40
						implicitHeight: 40
						onClicked: Wallpaper.reload()
					}
				}
				Flow {
					Layout.fillWidth: true
					spacing: 6
					visible: Wallpaper.folders.length > 0
					Repeater {
						model: [""].concat(Wallpaper.folders)
						Btn {
							required property string modelData
							implicitHeight: 32
							label: modelData === "" ? "All" : modelData
							toggleable: true
							toggled: Wallpaper.folderFilter === modelData
							toggledRadius: 14
							onClicked: Wallpaper.folderFilter = modelData
						}
					}
				}
				// decoding every thumbnail is costly, so the grid is only filled while this page is shown
				Flow {
					id: thumbs
					Layout.fillWidth: true
					spacing: 8
					readonly property int columns: 3
					Repeater {
						model: root.page === 6 ? Wallpaper.filtered : []
						Item {
							id: thumb
							required property var modelData
							readonly property bool current: Settings.wallpaper === modelData.path
							width: Math.floor((thumbs.width - (thumbs.columns - 1) * thumbs.spacing) / thumbs.columns)
							height: Math.round(width * 0.62)
							RoundedImage {
								anchors.fill: parent
								radius: thumb.current ? Theme.radiusSmall : Theme.radiusMedium
								source: "file://" + thumb.modelData.path
								Behavior on radius {
									NumberAnimation {
										duration: Theme.durShort
									}
								}
							}
							Rectangle {
								anchors.fill: parent
								radius: thumb.current ? Theme.radiusSmall : Theme.radiusMedium
								color: "transparent"
								border.width: thumb.current ? 3 : area.containsMouse ? 2 : 0
								border.color: thumb.current ? Theme.primary : Theme.outline
							}
							MouseArea {
								id: area
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: Wallpaper.apply(thumb.modelData.path)
							}
						}
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				visible: root.page === 7
				spacing: 8

				SectionLabel {
					text: "NOTCH AND HOME"
				}
				SettingRow {
					title: "Notch position"
					subtitle: "Where the idle notch sits and where Home opens"
				}
				PlacementPicker {
					value: Settings.notchEdge + ":" + Settings.notchAlign
					onPicked: v => {
						const p = v.split(":");
						Settings.notchEdge = p[0];
						Settings.notchAlign = p[1];
					}
				}

				SectionLabel {
					text: "WHEN OPENED WITH A SHORTCUT"
				}
				Repeater {
					model: [{ id: "apps", name: "Application launcher" }, { id: "clipboard", name: "Clipboard manager" }, { id: "calendar", name: "Calendar" }, { id: "notifications", name: "Notifications" }, { id: "power", name: "Power menu" }, { id: "record", name: "Screen recorder" }, { id: "settings", name: "Settings" }, { id: "popup", name: "Notification popup" }]
					ColumnLayout {
						id: ctx
						required property var modelData
						property bool expanded: false
						readonly property string stored: (Settings.placements || {})[modelData.id] || ""
						Layout.fillWidth: true
						spacing: 8
						SettingRow {
							title: ctx.modelData.name
							subtitle: ctx.stored === "" ? "Same as notch" : Settings.placementLabel(ctx.stored)
							Btn {
								icon: "chevron_right"
								implicitWidth: 40
								implicitHeight: 40
								rotation: ctx.expanded ? 270 : 90
								Behavior on rotation {
									NumberAnimation {
										duration: Theme.durMedium
										easing.type: Easing.OutCubic
									}
								}
								onClicked: ctx.expanded = !ctx.expanded
							}
						}
						PlacementPicker {
							visible: ctx.expanded
							allowInherit: true
							value: ctx.stored
							onPicked: v => Settings.setPlacement(ctx.modelData.id, v)
						}
					}
				}
			}
		}
	}
}
