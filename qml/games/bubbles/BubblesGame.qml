// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// "Bolle" - le bolle salgono piano dal basso, sparse su tutta l'altezza.
// Si toccano per farle scoppiare. Quando ne hai scoppiate abbastanza, hai vinto.
MiniGame {
    id: g
    title: qsTr("Bolle")
    age: qsTr("3-5 anni")
    levelCount: 3

    readonly property int need: 8
    property int done: 0

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        done = 0
    }

    function pop() {
        if (won) return
        done += 1
        snd.ok()
        if (done >= need) { snd.win(); win() }
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent

        Row {   // progresso
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

        Repeater {
            model: 6
            Item {
                id: bubble
                required property int index
                property real speed: 0.9 + index * 0.1     // px ogni 16 ms: lento
                property int  tint: index % 6
                property bool inited: false
                width: 132; height: 132

                function newX() { return Math.random() * Math.max(1, area.width - width) }

                function reseed() {
                    x = newX()
                    y = area.height + 30 + Math.random() * 140
                    tint = Math.floor(Math.random() * 6)
                    skin.scale = 1
                }

                Rectangle {
                    id: skin
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.playColors[bubble.tint]
                    opacity: 0.55
                    border.color: "white"
                    border.width: 5
                    Rectangle {   // riflesso
                        x: parent.width * 0.24; y: parent.height * 0.18
                        width: parent.width * 0.22; height: width
                        radius: width / 2
                        color: "white"
                        opacity: 0.6
                    }
                }

                Timer {
                    interval: 16
                    repeat: true
                    running: !g.won
                    onTriggered: {
                        if (!bubble.inited) {
                            // partenza: bolle sparse su tutta l'altezza
                            bubble.x = bubble.newX()
                            bubble.y = 40 + (area.height - 200) * (bubble.index / 5)
                            bubble.inited = true
                            return
                        }
                        bubble.y -= bubble.speed
                        if (bubble.y < -bubble.height - 30) bubble.reseed()
                    }
                }

                SequentialAnimation {
                    id: popAnim
                    NumberAnimation { target: skin; property: "scale"; from: 1.0; to: 1.7; duration: 150; easing.type: Easing.OutQuad }
                    ScriptAction { script: bubble.reseed() }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !g.won
                    onClicked: {
                        popAnim.start()
                        g.pop()
                    }
                }
            }
        }
    }
}
