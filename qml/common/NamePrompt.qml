// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Schermata iniziale di ogni gioco: si inserisce il nome del bambino.
// Emette accepted(nome) e si nasconde. "Salta" dà nome vuoto.
Item {
    id: root
    anchors.fill: parent
    visible: true

    signal accepted(string name)

    function commit(name) {
        root.accepted(name)
        root.visible = false
    }

    Rectangle { anchors.fill: parent; color: Theme.background }
    MouseArea { anchors.fill: parent }   // assorbe i tocchi sotto

    Column {
        anchors.centerIn: parent
        spacing: 28
        width: Math.min(root.width * 0.8, 620)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Come ti chiami?")
            font.pixelSize: 42
            font.bold: true
            color: Theme.text
        }

        Rectangle {
            width: parent.width
            height: 96
            radius: 24
            color: Theme.panel
            border.color: input.activeFocus ? Theme.accent : Theme.boardLine
            border.width: 4

            Text {
                anchors.centerIn: parent
                visible: input.text.length === 0
                text: qsTr("(scrivi qui il nome)")
                font.pixelSize: 28
                color: Theme.boardLine
            }
            TextInput {
                id: input
                anchors.fill: parent
                anchors.margins: 20
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                font.pixelSize: 40
                font.bold: true
                color: Theme.text
                maximumLength: 16
                clip: true
                onAccepted: root.commit(text.trim())
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            Rectangle {
                width: 210; height: 96; radius: 24
                color: Theme.accent
                scale: playMa.pressed ? 0.94 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }
                Row {
                    anchors.centerIn: parent
                    spacing: 12
                    Text { text: qsTr("Gioca"); font.pixelSize: 34; font.bold: true; color: "white" }
                    Text { text: "▶"; font.pixelSize: 34; color: "white" }
                }
                MouseArea { id: playMa; anchors.fill: parent; onClicked: root.commit(input.text.trim()) }
            }

            Rectangle {
                width: 150; height: 96; radius: 24
                color: Theme.panel
                border.color: Theme.boardLine
                border.width: 3
                scale: skipMa.pressed ? 0.94 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }
                Text { anchors.centerIn: parent; text: qsTr("Salta"); font.pixelSize: 28; color: Theme.text }
                MouseArea { id: skipMa; anchors.fill: parent; onClicked: root.commit("") }
            }
        }
    }

    onVisibleChanged: if (visible) input.forceActiveFocus()
    Component.onCompleted: input.forceActiveFocus()
}
