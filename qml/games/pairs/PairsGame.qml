// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// "Le coppie" - come il vero memory: prima le 6 carte si vedono tutte a
// faccia in su, poi si girano e si mescolano di posto; infine si cercano
// le 3 coppie girandone due alla volta.
MiniGame {
    id: g
    title: qsTr("Le coppie")
    age: qsTr("4-5 anni")
    levelCount: 6

    readonly property var pool: ["🐶", "🐱", "🐰", "🦊", "🐸", "🐵", "🐷", "🐨", "🦁", "🐼"]

    property var   deck: []                 // le 6 figure (identita' della carta)
    property var   slot: [0, 1, 2, 3, 4, 5]  // carta -> casella dove si trova ora
    property var   flipped: []
    property var   matched: []
    property bool  busy: false
    property string phase: "peek"           // peek | shuffle | guess

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        busy = false
        flipped = []
        matched = [false, false, false, false, false, false]
        slot = [0, 1, 2, 3, 4, 5]

        var p = pool.slice()
        for (var k = p.length - 1; k > 0; k--) {
            var j = Math.floor(Math.random() * (k + 1))
            var t = p[k]; p[k] = p[j]; p[j] = t
        }
        var three = p.slice(0, 3)
        deck = three.concat(three)

        phase = "peek"
        shuffleTimer.stop()
        peekTimer.restart()
    }

    // ----- fasi: si vedono tutte, poi si girano e si mescolano -----
    Timer {
        id: peekTimer
        interval: 2200
        onTriggered: {
            g.phase = "shuffle"
            shuffleTimer.left = 5
            shuffleTimer.restart()
        }
    }
    Timer {
        id: shuffleTimer
        property int left: 5
        interval: 380
        repeat: true
        onTriggered: {
            if (left <= 0) { stop(); g.phase = "guess"; return }
            g.doSwap()
            left -= 1
        }
    }

    function doSwap() {
        var s1 = Math.floor(Math.random() * 6)
        var s2 = (s1 + 1 + Math.floor(Math.random() * 5)) % 6
        var m = slot.slice()
        var a = m.indexOf(s1)
        var b = m.indexOf(s2)
        var t = m[a]; m[a] = m[b]; m[b] = t
        slot = m
        snd.tap()
    }

    // ----- griglia 3x2: posizione (in pixel) di ogni casella -----
    readonly property real cardW: 168
    readonly property real cardH: 196
    readonly property real gap: 24
    function gridW() { return cardW * 3 + gap * 2 }
    function gridH() { return cardH * 2 + gap }
    function slotX(s) { return (area.width  - gridW()) / 2 + (s % 3) * (cardW + gap) }
    function slotY(s) { return (area.height - gridH()) / 2 + Math.floor(s / 3) * (cardH + gap) }

    function faceUp(idx) {
        return phase === "peek" || matched[idx] || flipped.indexOf(idx) !== -1
    }

    function tapCard(idx) {
        if (phase !== "guess" || busy || won || matched[idx] || flipped.indexOf(idx) !== -1)
            return
        var f = flipped.concat([idx])
        flipped = f
        snd.tap()
        if (f.length === 2) {
            busy = true
            compare.start()
        }
    }

    Timer {
        id: compare
        interval: 750
        onTriggered: {
            var a = g.flipped[0], b = g.flipped[1]
            if (g.deck[a] === g.deck[b]) {
                var mm = g.matched.slice()
                mm[a] = true; mm[b] = true
                g.matched = mm
                snd.ok()
                if (mm.indexOf(false) === -1) { snd.win(); g.win() }
            } else {
                snd.nope(); g.wrong()
            }
            g.flipped = []
            g.busy = false
        }
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 4 }
            text: g.phase === "peek" ? "👀" : (g.phase === "shuffle" ? "🔀" : "👆")
            font.pixelSize: 40
        }

        Repeater {
            model: g.deck

            Rectangle {
                id: card
                required property int index
                required property var modelData
                width: g.cardW
                height: g.cardH
                radius: 22
                x: g.slotX(g.slot[index])
                y: g.slotY(g.slot[index])
                Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.InOutQuad } }
                Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.InOutQuad } }

                color: g.faceUp(index) ? Theme.panel : Theme.dirUp
                border.color: Theme.boardLine
                border.width: 3
                scale: g.matched[index] ? 1.0 : (pma.pressed ? 0.95 : 1)
                Behavior on scale { NumberAnimation { duration: 90 } }

                Text {
                    anchors.centerIn: parent
                    text: g.faceUp(card.index) ? card.modelData : "❓"
                    font.pixelSize: g.faceUp(card.index) ? 96 : 60
                    color: g.faceUp(card.index) ? Theme.text : "white"
                }

                MouseArea {
                    id: pma
                    anchors.fill: parent
                    enabled: g.phase === "guess" && !g.won
                    onClicked: g.tapCard(card.index)
                }
            }
        }
    }
}
