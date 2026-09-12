// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// "Dov'è il coniglio?" - il coniglio si nasconde sotto un bicchiere; i
// bicchieri si mescolano più volte (e il coniglio va con il suo bicchiere).
// Poi si tocca quello giusto. Il coniglio si vede SOLO quando il bicchiere
// è alzato.
MiniGame {
    id: g
    title: qsTr("Dov'è il coniglio?")
    age: qsTr("4-5 anni")
    levelCount: 5

    property int  hiddenCup: 0            // id del bicchiere che nasconde
    property var  cupSlot: [0, 1, 2]      // id bicchiere -> posizione (0..2)
    property string phase: "peek"        // peek | shuffle | guess | done
    property int  peekWrongCup: -1

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function slotX(s) {
        var gap = Math.min(230, (area.width - 40) / 3)
        var total = gap * 3
        return (area.width - total) / 2 + s * gap + (gap - 150) / 2
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        peekWrongCup = -1
        cupSlot = [0, 1, 2]
        hiddenCup = Math.floor(Math.random() * 3)
        phase = "peek"
        shuffleTimer.stop()
        peekTimer.restart()
    }

    // dopo aver mostrato il coniglio: i bicchieri scendono, poi si mescolano
    Timer {
        id: peekTimer
        interval: 1300
        onTriggered: { g.phase = "shuffle"; startShuffle.restart() }
    }
    Timer {
        id: startShuffle
        interval: 450
        onTriggered: {
            shuffleTimer.left = Math.min(3 + g.levelIndex, 6)
            shuffleTimer.restart()
        }
    }
    Timer {
        id: shuffleTimer
        property int left: 3
        interval: 430
        repeat: true
        onTriggered: {
            if (left <= 0) { stop(); g.phase = "guess"; return }
            g.doSwap()
            left -= 1
        }
    }
    Timer { id: wrongTimer; interval: 700; onTriggered: g.peekWrongCup = -1 }

    function doSwap() {
        var s1 = Math.floor(Math.random() * 3)
        var s2 = (s1 + 1 + Math.floor(Math.random() * 2)) % 3
        var m = cupSlot.slice()
        for (var id = 0; id < 3; id++) {
            if (m[id] === s1) m[id] = s2
            else if (m[id] === s2) m[id] = s1
        }
        cupSlot = m
        snd.tap()
    }

    function tapCup(id) {
        if (phase !== "guess" || won) return
        if (id === hiddenCup) {
            phase = "done"
            snd.win(); win()
        } else {
            snd.nope(); wrong()
            peekWrongCup = id
            wrongTimer.restart()
        }
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 10 }
            text: g.phase === "guess" ? "👆" : (g.phase === "shuffle" ? "🔀" : "👀")
            font.pixelSize: 46
        }

        Repeater {
            model: 3
            Item {
                id: cup
                required property int index
                width: 150; height: 210
                x: g.slotX(g.cupSlot[index])
                y: area.height / 2 - height / 2 + 20
                Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                z: g.cupSlot[index]

                readonly property bool up:
                    g.phase === "peek"
                    || (g.phase === "done" && index === g.hiddenCup)
                    || g.peekWrongCup === index

                Text {   // il coniglio, seduto per terra; si vede solo se alzato
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height - 104
                    text: "🐰"
                    font.pixelSize: 92
                    visible: cup.index === g.hiddenCup && cup.up
                }

                Item {   // il bicchiere che si alza / abbassa
                    id: body
                    width: parent.width
                    height: parent.height
                    y: cup.up ? -128 : 0
                    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutQuad } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: Theme.dirLeft
                        border.color: Theme.boardLine
                        border.width: 4
                    }
                    Rectangle {   // bordo superiore
                        width: parent.width; height: 26; radius: 13
                        color: Qt.darker(Theme.dirLeft, 1.15)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: g.phase === "guess" && !g.won
                    onClicked: g.tapCup(cup.index)
                }
            }
        }
    }
}
