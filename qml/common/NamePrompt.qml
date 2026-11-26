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

    Scenery { theme: "prato" }
    MouseArea { anchors.fill: parent }   // assorbe i tocchi sotto

    Column {
        anchors.centerIn: parent
        spacing: 26
        width: Math.min(root.width * 0.8, 620)

        AppIcon {
            id: mascot
            anchors.horizontalCenter: parent.horizontalCenter
            name: "teddy"
            size: Math.min(150, root.height * 0.2)
            SequentialAnimation on rotation {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { from: -8; to: 8; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { from: 8; to: -8; duration: 900; easing.type: Easing.InOutSine }
            }
        }

        TitlePill {
            anchors.horizontalCenter: parent.horizontalCenter
            title: qsTr("Come ti chiami?")
            titleSize: 42
        }

        Rectangle {
            width: parent.width
            height: 96
            radius: 48
            color: "white"
            border.color: input.activeFocus ? Theme.accent : "#FFD54F"
            border.width: 5

            Candy {}
            Text {
                anchors.centerIn: parent
                visible: input.text.length === 0
                text: qsTr("(scrivi qui il nome)")
                font.pixelSize: 28
                color: "#BCAAA4"
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

            CandyButton {
                width: 230; height: 96
                text: qsTr("Gioca")
                icon: "ui/play"
                textSize: 36
                onClicked: root.commit(input.text.trim())
            }
            CandyButton {
                width: 160; height: 96
                text: qsTr("Salta")
                color: Theme.dirLeft
                textSize: 30
                onClicked: root.commit("")
            }
        }
    }

    onVisibleChanged: if (visible) input.forceActiveFocus()
    Component.onCompleted: input.forceActiveFocus()
}
