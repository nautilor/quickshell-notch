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

	signal picked(string path)
	signal cancelled

	function pathOf(url) {
		return decodeURIComponent(url.toString().replace(/^file:\/\//, ""));
	}

	FolderListModel {
		id: folders
		folder: root.startFolder
		nameFilters: root.dirsOnly ? [] : root.filters
		showFiles: !root.dirsOnly
		showDirs: true
		showDirsFirst: true
		showDotAndDotDot: false
		showHidden: false
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
			Txt {
				Layout.fillWidth: true
				text: root.pathOf(folders.folder)
				elide: Text.ElideLeft
				font.pixelSize: 12
				color: Theme.surfaceVariantFg
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
