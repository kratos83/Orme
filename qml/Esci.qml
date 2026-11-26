// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Chiede conferma prima di uscire dall'applicazione. Viene mostrato sopra la
// schermata corrente quando si tocca "Esci", si preme il tasto "indietro" di
// Android o si chiude la finestra; "Annulla" torna dove si era.
Item {
    id: root
    anchors.fill: parent
    signal exitRequested()

    Scenery { theme: "tramonto" }
    MouseArea { anchors.fill: parent }   // assorbe i tocchi sulla schermata sotto
    Component.onCompleted: forceActiveFocus()

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(520, root.width - 40)
        height: content.implicitHeight + 64
        radius: 48
        color: "white"
        border.color: "#FFCA28"
        border.width: 6

        Candy { depth: 10 }

        Column {
            id: content
            anchors.centerIn: parent
            spacing: 24
            width: parent.width - 56

            AppIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "wave-hand"
                size: 150
                transformOrigin: Item.Bottom
                SequentialAnimation on rotation {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { from: -12; to: 14; duration: 450; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 14; to: -12; duration: 450; easing.type: Easing.InOutSine }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: qsTr("Vuoi uscire veramente?")
                font.pixelSize: 38
                font.bold: true
                color: Theme.title
            }

            CandyButton {   // resta a giocare
                width: parent.width; height: 90
                text: qsTr("Annulla")
                icon: "ui/play"
                onClicked: root.exitRequested()
            }
            CandyButton {
                width: parent.width; height: 74
                text: qsTr("Esci")
                icon: "door"
                textSize: 28
                color: Theme.danger
                onClicked: Qt.exit(0)
            }
        }
    }
}
