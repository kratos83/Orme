// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Sillabe: le sillabe di una parola sono mescolate in basso; toccale
// nell'ordine giusto per ricomporre la parola.
MiniGame {
    id: g
    title: qsTr("Sillabe")
    age: qsTr("6-7 anni")
    levelCount: 10

    readonly property var words: [
        ["CA", "SA"], ["ME", "LA"], ["SO", "LE"], ["GAT", "TO"], ["CA", "NE"],
        ["PA", "NE"], ["LET", "TO"], ["POR", "TA"], ["SCUO", "LA"], ["AL", "BE", "RO"],
        ["FIO", "RE"], ["MA", "RE"], ["LU", "NA"], ["STEL", "LA"], ["LI", "BRO"],
        ["TRE", "NO"], ["NA", "VE"], ["PE", "SCE"], ["FOR", "MI", "CA"], ["TA", "VO", "LO"],
        ["FI", "NE", "STRA"], ["BAM", "BI", "NO"], ["GIAR", "DI", "NO"], ["QUA", "DER", "NO"],
        ["ZAI", "NO"], ["UO", "VO"], ["PIAT", "TO"], ["GOM", "MA"], ["ZUC", "CHE", "RO"], ["FOR", "MAG", "GIO"]
    ]

    property int wordIdx: 0
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
        wordIdx = Math.floor(Math.random() * words.length)
        var w = words[wordIdx]
        var arr = []
        for (var k = 0; k < w.length; k++) arr.push({ text: w[k], pos: k })
        chips = shuffle(arr)
    }

    function tapChip(chip) {
        if (won) return
        if (chip.pos === nextIndex) {
            snd.ok()
            built += chip.text
            nextIndex += 1
            chips = chips.filter((c) => c !== chip)
            if (nextIndex >= words[wordIdx].length) { snd.win(); win() }
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
            width: parent.width

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(220, builtText.implicitWidth + 40)
                height: 90
                radius: 20
                color: Theme.panel
                border.color: Theme.boardLine
                border.width: 3
                Text { id: builtText; anchors.centerIn: parent; text: g.built; font.pixelSize: 40; font.bold: true; color: Theme.text }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16
                Repeater {
                    model: g.chips
                    Rectangle {
                        id: chip
                        required property var modelData
                        width: 90; height: 90; radius: 20
                        color: Theme.dirRight
                        scale: chipMa.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text { anchors.centerIn: parent; text: chip.modelData.text; font.pixelSize: 30; font.bold: true; color: "white" }
                        MouseArea { id: chipMa; anchors.fill: parent; onClicked: g.tapChip(chip.modelData) }
                    }
                }
            }
        }
    }
}
