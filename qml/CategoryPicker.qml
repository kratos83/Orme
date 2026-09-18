// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Schermata iniziale: scegli "Infanzia" o "Primaria", poi si entra nella
// griglia dei giochi di quella sola categoria (Launcher.category).
Item {
    id: root
    signal categorySelected(string category)

    Rectangle { anchors.fill: parent; color: Theme.background }

    Rectangle {   // pulsante Esci, in alto a destra
        anchors { top: parent.top; right: parent.right; margins: 18 }
        width: 100; height: 60; radius: 30
        color: Theme.panel
        border.color: Theme.boardLine
        border.width: 3
        scale: m_esci.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        Text { anchors.centerIn: parent; text: "Esci"; font.pixelSize: 30; font.bold: true; font.italic: true; color: Theme.text }
        MouseArea { id: m_esci; anchors.fill: parent; onClicked: Qt.exit(0) }
    }

    Text {
        anchors { top: parent.top; topMargin: 34; horizontalCenter: parent.horizontalCenter }
        text: qsTr("Orme")
        font.pixelSize: 44
        font.bold: true
        color: Theme.text
    }

    Text {
        id: sub
        anchors { top: parent.top; topMargin: 92; horizontalCenter: parent.horizontalCenter }
        text: qsTr("Per chi sono i giochi oggi?")
        font.pixelSize: 24
        color: Theme.text
    }

    Row {
        anchors.centerIn: parent
        spacing: 40

        Rectangle {
            id: infanziaBtn
            width: 300; height: 300; radius: 36
            color: Theme.dirRight
            scale: infanziaMa.pressed ? 0.95 : 1
            Behavior on scale { NumberAnimation { duration: 90 } }
            Column {
                anchors.centerIn: parent
                spacing: 12
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🧸"; font.pixelSize: 90 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Infanzia"); font.pixelSize: 32; font.bold: true; color: "white" }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("3-5 anni"); font.pixelSize: 18; color: "white" }
            }
            MouseArea { id: infanziaMa; anchors.fill: parent; onClicked: root.categorySelected("infanzia") }
        }

        Rectangle {
            id: primariaBtn
            width: 300; height: 300; radius: 36
            color: Theme.dirUp
            scale: primariaMa.pressed ? 0.95 : 1
            Behavior on scale { NumberAnimation { duration: 90 } }
            Column {
                anchors.centerIn: parent
                spacing: 12
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🎒"; font.pixelSize: 90 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Primaria"); font.pixelSize: 32; font.bold: true; color: "white" }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("6-10 anni"); font.pixelSize: 18; color: "white" }
            }
            MouseArea { id: primariaMa; anchors.fill: parent; onClicked: root.categorySelected("primaria") }
        }
    }

    Text {
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
        onLinkActivated: (link) => Qt.openUrlExternally(link)
    }
}
