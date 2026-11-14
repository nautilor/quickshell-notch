import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.config

// Small in-shell image file browser (there is no system file dialog to rely on under a layer shell).
Item {
	id: root

	property url startFolder: "file://" + Quickshell.env("HOME")
	property var filters: ["*.png", "*.svg", "*.jpg", "*.jpeg", "*.webp", "*.ico", "*.xpm", "*.bmp", "*.gif"]

	// folder chooser mode: only directories are listed and a button picks the current one
	property bool dirsOnly: false
	property bool showHidden: false

	signal picked(string path)
	signal cancelled

	function pathOf(url) {
		return decodeURIComponent(url.toString().replace(/^file:\/\//, ""));
	}

	// Enter in the path field: an image file is picked, anything else is opened as a folder
	function go(raw) {
		let p = raw.trim();
		if (p.startsWith("~"))
			p = Quickshell.env("HOME") + p.slice(1);
		if (p === "")
			return;
		const isFile = !root.dirsOnly && !p.endsWith("/") && root.filters.some(f => p.toLowerCase().endsWith(f.slice(1)));
		if (isFile)
			root.picked(p);
		else
			folders.folder = "file://" + p;
	}

	FolderListModel {
		id: folders
		folder: root.startFolder
		nameFilters: root.dirsOnly ? [] : root.filters
		showFiles: !root.dirsOnly
		showDirs: true
		showDirsFirst: true
		showDotAndDotDot: false
		showHidden: root.showHidden
		sortField: FolderListModel.Name
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 8

		RowLayout {
			Layout.fillWidth: true
			spacing: 8
			Btn {
				icon: "arrow_back"
				implicitWidth: 36
				implicitHeight: 36
				onClicked: folders.folder = folders.parentFolder
			}
			Field {
				id: pathField
				Layout.fillWidth: true
				implicitHeight: 36
				color: Theme.surfaceContainerHighest
				placeholder: "Type a path and press Enter"
				input.font.pixelSize: 12
				Component.onCompleted: text = root.pathOf(folders.folder)
				onAccepted: root.go(text)
				Connections {
					target: folders
					function onFolderChanged() {
						pathField.text = root.pathOf(folders.folder);
					}
				}
			}
			Btn {
				icon: root.showHidden ? "visibility" : "visibility_off"
				implicitWidth: 36
				implicitHeight: 36
				toggleable: true
				toggled: root.showHidden
				onClicked: root.showHidden = !root.showHidden
			}
			Btn {
				visible: root.dirsOnly
				icon: "check"
				label: "Select"
				variant: 1
				implicitHeight: 36
				onClicked: root.picked(root.pathOf(folders.folder))
			}
			Btn {
				icon: "close"
				implicitWidth: 36
				implicitHeight: 36
				onClicked: root.cancelled()
			}
		}

		ListView {
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true
			spacing: 2
			model: folders
			boundsBehavior: Flickable.StopAtBounds

			delegate: Rectangle {
				id: entry
				required property string fileName
				required property url fileUrl
				required property bool fileIsDir
				width: ListView.view.width
				height: 40
				radius: Theme.radiusSmall
				color: area.containsMouse ? Theme.secondaryContainer : "transparent"

				Item {
					id: thumb
					width: 28
					height: 28
					anchors.left: parent.left
					anchors.leftMargin: 8
					anchors.verticalCenter: parent.verticalCenter
					Icon {
						visible: entry.fileIsDir
						anchors.centerIn: parent
						name: "folder"
						size: 24
						color: Theme.primary
					}
					Image {
						visible: !entry.fileIsDir
						anchors.fill: parent
						fillMode: Image.PreserveAspectFit
						asynchronous: true
						sourceSize: Qt.size(56, 56)
						source: entry.fileIsDir ? "" : entry.fileUrl
					}
				}
				Txt {
					anchors.left: thumb.right
					anchors.leftMargin: 10
					anchors.right: parent.right
					anchors.rightMargin: 8
					anchors.verticalCenter: parent.verticalCenter
					text: entry.fileName
				}
				MouseArea {
					id: area
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						if (entry.fileIsDir)
							folders.folder = entry.fileUrl;
						else
							root.picked(root.pathOf(entry.fileUrl));
					}
				}
			}
		}
	}
}
