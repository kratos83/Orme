// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Soggetto e predicato: una frase divisa in due pezzi; a volte si chiede di
// toccare il soggetto, a volte il predicato.
MiniGame {
    id: g
    title: qsTr("Soggetto e predicato")
    age: qsTr("8-9 anni")
    levelCount: 10

    readonly property var sentences: [
        { subj: qsTr("L'aereo"), pred: qsTr("atterra") },
        { subj: qsTr("La sarta"), pred: qsTr("cuce") },
        { subj: qsTr("Il vento"), pred: qsTr("soffia") },
        { subj: qsTr("Il gatto"), pred: qsTr("dorme") },
        { subj: qsTr("I bambini"), pred: qsTr("giocano") },
        { subj: qsTr("La maestra"), pred: qsTr("spiega") },
        { subj: qsTr("Il sole"), pred: qsTr("splende") },
        { subj: qsTr("Il cane"), pred: qsTr("abbaia") },
        { subj: qsTr("Le foglie"), pred: qsTr("cadono") },
        { subj: qsTr("Il treno"), pred: qsTr("parte") },
        { subj: qsTr("La mamma"), pred: qsTr("cucina") },
        { subj: qsTr("Gli uccelli"), pred: qsTr("cantano") },
        { subj: qsTr("Il bambino"), pred: qsTr("corre") },
        { subj: qsTr("La pioggia"), pred: qsTr("cade") },
        { subj: qsTr("Il pesce"), pred: qsTr("nuota") }
    ]

    property var current: sentences[0]
    property string asking: "subj"   // "subj" o "pred"
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        current = sentences[Math.floor(Math.random() * sentences.length)]
        asking = Math.random() < 0.5 ? "subj" : "pred"
    }

    function pick(part) {
        if (answered) return
        if (part === asking) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Column {
            anchors.centerIn: parent
            spacing: 40

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: g.asking === "subj" ? qsTr("Tocca il soggetto") : qsTr("Tocca il predicato")
                font.pixelSize: 30
                font.bold: true
                color: Theme.text
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18

                Rectangle {
                    id: subjChunk
                    width: Math.max(150, subjText.implicitWidth + 40); height: 96; radius: 20
                    color: Theme.dirUp
                    opacity: g.answered && g.asking !== "subj" ? 0.4 : 1
                    scale: subjMa.pressed ? 0.95 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }
                    Text { id: subjText; anchors.centerIn: parent; text: g.current.subj; font.pixelSize: 28; font.bold: true; color: "white" }
                    MouseArea { id: subjMa; anchors.fill: parent; enabled: !g.won; onClicked: g.pick("subj") }
                }

                Rectangle {
                    id: predChunk
                    width: Math.max(150, predText.implicitWidth + 40); height: 96; radius: 20
                    color: Theme.dirDown
                    opacity: g.answered && g.asking !== "pred" ? 0.4 : 1
                    scale: predMa.pressed ? 0.95 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }
                    Text { id: predText; anchors.centerIn: parent; text: g.current.pred; font.pixelSize: 28; font.bold: true; color: "white" }
                    MouseArea { id: predMa; anchors.fill: parent; enabled: !g.won; onClicked: g.pick("pred") }
                }
            }
        }
    }
}
