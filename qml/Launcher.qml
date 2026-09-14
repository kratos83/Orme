// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Menu iniziale: 20 riquadri da toccare, in una griglia che si adatta alla
// larghezza (fino a 6 per riga) e scorre in verticale.
Item {
    id: root
    signal gameSelected(string game)
    signal infoRequested()

    Rectangle { anchors.fill: parent; color: Theme.background }

    Text {
        id: heading
        anchors { top: parent.top; topMargin: 20; horizontalCenter: parent.horizontalCenter }
        text: qsTr("Scegli un gioco")
        font.pixelSize: 38
        font.bold: true
        color: Theme.text
    }

    Rectangle {   // pulsante Info, in alto a destra
        anchors { top: parent.top; right: parent.right; margins: 18 }
        width: 60; height: 60; radius: 30
        color: Theme.panel
        border.color: Theme.boardLine
        border.width: 3
        scale: infoMa.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        Text { anchors.centerIn: parent; text: "i"; font.pixelSize: 30; font.bold: true; font.italic: true; color: Theme.text }
        MouseArea { id: infoMa; anchors.fill: parent; onClicked: root.infoRequested() }
    }

    Flickable {
        id: flick
        anchors {
            top: heading.bottom; topMargin: 14
            left: parent.left; right: parent.right
            bottom: footer.top
        }
        contentWidth: width
        contentHeight: grid.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Grid {
            id: grid
            anchors.horizontalCenter: parent.horizontalCenter
            columns: Math.max(3, Math.min(6, Math.floor((flick.width - 40) / 214)))
            rowSpacing: 18
            columnSpacing: 18

            Repeater {
                model: Catalog.games
                GameTile {
                    required property var modelData
                    title: modelData.title
                    age: modelData.age
                    baseColor: modelData.c
                    iconKind: modelData.icon ? modelData.icon : ""
                    emoji: modelData.e ? modelData.e : ""
                    onClicked: root.gameSelected(modelData.id)
                }
            }
        }
    }

    Text {
        id: footer
        width: parent.width - 40
        anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        textFormat: Text.RichText
        text: "© 2026 Angelo Scarnà - software libero (GPLv3). Per info contattare: " +
              "<a href=\"mailto:angelo.scarna@primanotanet.it\">angelo.scarna@primanotanet.it</a>"
        linkColor: Theme.accentDark
        font.pixelSize: 15
        color: Theme.text
        opacity: 1
        onLinkActivated: (link) => Qt.openUrlExternally(link)

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            property bool onLink: false
            cursorShape: onLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPositionChanged: (m) => onLink = footer.linkAt(m.x, m.y) !== ""
            onExited: onLink = false
            onClicked: (m) => {
                var l = footer.linkAt(m.x, m.y)
                if (l !== "") Qt.openUrlExternally(l)
            }
        }
    }
}
