// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Indovina la parola: leggi l'indovinello, tocca la parola giusta fra 4.
MiniGame {
    id: g
    title: qsTr("Indovina la parola")
    age: qsTr("6-8 anni")
    levelCount: 12

    readonly property var entries: [
        { clue: qsTr("È un frutto giallo e curvo, piace alle scimmie"), word: qsTr("banana") },
        { clue: qsTr("Miagola e cattura i topi"), word: qsTr("gatto") },
        { clue: qsTr("Abbaia e scodinzola quando è contento"), word: qsTr("cane") },
        { clue: qsTr("Ci dormi di notte"), word: qsTr("letto") },
        { clue: qsTr("La usi per scrivere sul quaderno"), word: qsTr("matita") },
        { clue: qsTr("Splende in cielo di giorno"), word: qsTr("sole") },
        { clue: qsTr("Splende in cielo di notte"), word: qsTr("luna") },
        { clue: qsTr("Ha le ali e vola tra i fiori"), word: qsTr("farfalla") },
        { clue: qsTr("Rossa o verde, cresce sull'albero"), word: qsTr("mela") },
        { clue: qsTr("Ha il collo lunghissimo"), word: qsTr("giraffa") },
        { clue: qsTr("Vive in acqua e ha le branchie"), word: qsTr("pesce") },
        { clue: qsTr("Ci vai con lo zaino sulle spalle"), word: qsTr("scuola") },
        { clue: qsTr("Bianca e fredda, cade d'inverno"), word: qsTr("neve") },
        { clue: qsTr("Ha quattro ruote e ti porta in giro"), word: qsTr("automobile") },
        { clue: qsTr("Vola alto nel cielo con le ali di metallo"), word: qsTr("aereo") },
        { clue: qsTr("Ha le radici, il tronco e le foglie"), word: qsTr("albero") }
    ]

    property int targetIndex: 0
    property var choices: []
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function shuffle(a) {
        var r = a.slice()
        for (var k = r.length - 1; k > 0; k--) {
            var j = Math.floor(Math.random() * (k + 1))
            var t = r[k]; r[k] = r[j]; r[j] = t
        }
        return r
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        targetIndex = Math.floor(Math.random() * entries.length)
        var pool = []
        for (var k = 0; k < entries.length; k++) if (k !== targetIndex) pool.push(k)
        pool = shuffle(pool).slice(0, 3)
        pool.push(targetIndex)
        choices = shuffle(pool)
    }

    function pick(idx) {
        if (answered) return
        if (idx === targetIndex) {
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
            spacing: 30
            width: Math.min(parent.width - 40, 560)

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: g.entries[g.targetIndex].clue
                font.pixelSize: 26
                font.bold: true
                color: Theme.text
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 2
                rowSpacing: 16
                columnSpacing: 16
                Repeater {
                    model: g.choices
                    Rectangle {
                        id: opt
                        required property int modelData
                        required property int index
                        width: 260; height: 84; radius: 18
                        color: Theme.playColors[index % Theme.playColors.length]
                        opacity: g.answered && opt.modelData !== g.targetIndex ? 0.4 : 1
                        scale: optMa.pressed ? 0.95 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text { anchors.centerIn: parent; text: g.entries[opt.modelData].word; font.pixelSize: 24; font.bold: true; color: "white" }
                        MouseArea { id: optMa; anchors.fill: parent; enabled: !g.won; onClicked: g.pick(opt.modelData) }
                    }
                }
            }
        }
    }
}
