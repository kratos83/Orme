// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Raccogli i frutti" - i frutti colorati scendono piano dall'alto, si
// toccano per metterli nel cesto. Quando ne hai raccolti abbastanza, hai vinto.
MiniGame {
    id: g
    title: qsTr("Raccogli i frutti")
    age: qsTr("3-5 anni")
    levelCount: 3

    readonly property int need: 8
    readonly property var fruits: ["🍎", "🍌", "🍓", "🍇", "🍊", "🍐", "🍑", "🍒"]
    property int done: 0

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        done = 0
    }

    function pick() {
        if (won) return
        done += 1
        snd.ok()
        if (done >= need) { snd.win(); win() }
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent

        Row {
            anchors { top: parent.top; topMargin: 6; horizontalCenter: parent.horizontalCenter }
            spacing: 8
            Repeater {
                model: g.need
                Rectangle {
                    width: 16; height: 16; radius: 8
                    color: index < g.done ? Theme.accent : Theme.boardLine
                }
            }
        }

        Text {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
            text: "🧺"
            font.pixelSize: 100
        }

        Repeater {
            model: 5
            Item {
                id: fruit
                required property int index
                property real speed: 1.2 + index * 0.35     // px ogni 16 ms: lento
                property int  tint: index % 6
                width: 104; height: 104
                x: Math.random() * 600
                y: -140 - index * 150

                function reseed() {
                    x = Math.random() * Math.max(1, area.width - width)
                    y = -130
                    tint = Math.floor(Math.random() * 6)
                    face.text = g.fruits[Math.floor(Math.random() * g.fruits.length)]
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 96; height: 96
                    radius: 48
                    color: Theme.playColors[fruit.tint]
                    border.color: "white"
                    border.width: 4
                }
                Text {
                    id: face
                    anchors.centerIn: parent
                    text: g.fruits[fruit.index % g.fruits.length]
                    font.pixelSize: 60
                }

                Timer {
                    interval: 16
                    repeat: true
                    running: !g.won
                    onTriggered: {
                        fruit.y += fruit.speed
                        if (fruit.y > area.height) fruit.reseed()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !g.won
                    onClicked: { fruit.reseed(); g.pick() }
                }
            }
        }
    }
}
