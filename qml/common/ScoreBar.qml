// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Il punteggio del bambino, mostrato con una faccina e il numero.
// Anche se si guadagnano piu' faccine insieme, il numero sale SEMPRE
// una unita' alla volta (mai a scatti di 2 o 3), con un saltino a ogni unita'.
Item {
    id: root
    property int value: 0            // punteggio vero (bersaglio)
    property int displayValue: 0     // quello mostrato

    implicitWidth: pill.width
    implicitHeight: pill.height

    Rectangle {
        id: pill
        width: row.implicitWidth + 36
        height: 64
        radius: 32
        color: Theme.panel
        border.color: Theme.boardLine
        border.width: 3

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            Text { text: "😊"; font.pixelSize: 34; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: root.displayValue
                font.pixelSize: 34
                font.bold: true
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    SequentialAnimation {
        id: bump
        NumberAnimation { target: pill; property: "scale"; from: 1.0; to: 1.18; duration: 130; easing.type: Easing.OutBack }
        NumberAnimation { target: pill; property: "scale"; to: 1.0; duration: 130 }
    }

    // sale di 1 alla volta verso "value", un saltino per ogni unita'
    Timer {
        id: tick
        interval: 260
        repeat: true
        onTriggered: {
            if (root.displayValue < root.value) {
                root.displayValue += 1
                bump.restart()
            } else {
                stop()
            }
        }
    }

    onValueChanged: {
        if (value > displayValue) tick.restart()
        else displayValue = value   // es. si azzera a inizio partita
    }
}
