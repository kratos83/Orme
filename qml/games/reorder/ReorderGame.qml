// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Riordina la frase: le parole di una frase sono mescolate; toccale
// nell'ordine giusto per ricomporla.
MiniGame {
    id: g
    title: qsTr("Riordina la frase")
    age: qsTr("7-9 anni")
    levelCount: 8

    readonly property var sentences: [
        ["Il", "gatto", "è", "nascosto", "sotto", "la", "sedia"],
        ["La", "mia", "amica", "si", "chiama", "Alberta"],
        ["Il", "sole", "splende", "alto", "nel", "cielo"],
        ["Il", "cane", "corre", "veloce", "nel", "prato"],
        ["La", "mamma", "prepara", "la", "torta", "di", "mele"],
        ["I", "bambini", "giocano", "felici", "in", "giardino"],
        ["Il", "treno", "arriva", "sempre", "in", "orario"],
        ["La", "maestra", "legge", "una", "bella", "storia"],
        ["Le", "foglie", "cadono", "gialle", "in", "autunno"],
        ["Il", "pesce", "nuota", "veloce", "nel", "mare"],
        ["Mio", "fratello", "suona", "la", "chitarra"],
        ["La", "neve", "copre", "tutta", "la", "montagna"],
        ["Il", "nonno", "racconta", "storie", "divertenti"],
        ["Gli", "uccelli", "cantano", "sopra", "l'albero"],
        ["Il", "vento", "soffia", "forte", "stasera"]
    ]

    property int sentenceIdx: 0
    property var chips: []      // { text, pos } mescolati
    property int nextIndex: 0
    property string built: ""

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
        built = ""
        nextIndex = 0
        sentenceIdx = Math.floor(Math.random() * sentences.length)
        var s = sentences[sentenceIdx]
        var arr = []
        for (var k = 0; k < s.length; k++) arr.push({ text: s[k], pos: k })
        chips = shuffle(arr)
    }

    function tapChip(chip) {
        if (won) return
        if (chip.pos === nextIndex) {
            snd.ok()
            built += (built === "" ? "" : " ") + chip.text
            nextIndex += 1
            chips = chips.filter((c) => c !== chip)
            if (nextIndex >= sentences[sentenceIdx].length) { snd.win(); win() }
        } else {
            snd.nope(); wrong()
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Column {
            anchors.centerIn: parent
            spacing: 36
            width: parent.width

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 60, Math.max(260, builtText.implicitWidth + 40))
                height: 90
                radius: 20
                color: Theme.panel
                border.color: Theme.boardLine
                border.width: 3
                Text {
                    id: builtText
                    anchors.centerIn: parent
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: g.built
                    font.pixelSize: 26
                    font.bold: true
                    color: Theme.text
                }
            }

            Flow {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 60
                spacing: 14

                Repeater {
                    model: g.chips
                    Rectangle {
                        id: chip
                        required property var modelData
                        width: Math.max(80, chipText.implicitWidth + 28); height: 70; radius: 18
                        color: Theme.dirRight
                        scale: chipMa.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text { id: chipText; anchors.centerIn: parent; text: chip.modelData.text; font.pixelSize: 22; font.bold: true; color: "white" }
                        MouseArea { id: chipMa; anchors.fill: parent; onClicked: g.tapChip(chip.modelData) }
                    }
                }
            }
        }
    }
}
