// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// "Palloncini in fila" - si toccano i palloncini dal più piccolo al più
// grande. Concetto: mettere in ordine per grandezza.
MiniGame {
    id: g
    title: qsTr("Palloncini in fila")
    age: qsTr("3-5 anni")
    levelCount: 8

    property var  sizes: [70, 110, 150]     // dimensioni dei palloncini
    property int  next: 0                    // prossimo (indice per grandezza)
    property var  taken: [false, false, false]

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        next = 0
        var n = 3
        var base = [70, 105, 140, 175].slice(0, n)
        var s = base.slice()
        for (var k = s.length - 1; k > 0; k--) {
            var j = Math.floor(Math.random() * (k + 1))
            var t = s[k]; s[k] = s[j]; s[j] = t
        }
        sizes = s
        taken = []
        for (var m = 0; m < n; m++) taken.push(false)
    }

    // rango di un palloncino: 0 = più piccolo
    function rank(idx) {
        var r = 0
        for (var k = 0; k < sizes.length; k++)
            if (sizes[k] < sizes[idx]) r++
        return r
    }

    function tap(idx) {
        if (won || taken[idx]) return
        if (rank(idx) === next) {
            var tk = taken.slice()
            tk[idx] = true
            taken = tk
            next += 1
            snd.ok()
            if (next >= sizes.length) { snd.win(); win() }
        } else {
            snd.nope(); wrong()
        }
    }

    // ---------- contenuto ----------
    Row {
        anchors.centerIn: parent
        spacing: 50
        Repeater {
            model: g.sizes
            Item {
                id: bal
                required property int index
                required property var modelData
                width: 190; height: 260

                Column {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "🎈"
                        font.pixelSize: bal.modelData
                        opacity: g.taken[bal.index] ? 0.25 : 1
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 3; height: 60
                        color: Theme.boardLine
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !g.won && !g.taken[bal.index]
                    onClicked: g.tap(bal.index)
                }
            }
        }
    }
}
