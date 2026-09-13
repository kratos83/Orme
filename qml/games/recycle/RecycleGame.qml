// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "La raccolta differenziata" - un oggetto al centro, tre bidoni colorati
// (plastica/gialla, carta/blu, vetro/verde): si trascina l'oggetto nel
// bidone giusto. Stessa meccanica di trascinamento di SortGame, ma con
// bidoni fissi (il concetto da imparare e' la categoria, non la regola).
GameScaffold {
    id: scaffold
    title: qsTr("La raccolta differenziata")
    age: qsTr("3-5 anni")
    showNext: won

    onRestartRequested: load()
    onNextRequested: goNext()
    onWinFinished: goNext()

    readonly property int perRound: 9

    // key = indice del bidone; colorIndex punta a Theme.playColors (i colori
    // reali della raccolta differenziata: plastica/giallo, carta/blu, vetro/verde)
    readonly property var bins: [
        { key: "plastica", colorIndex: 2 },
        { key: "carta",    colorIndex: 1 },
        { key: "vetro",    colorIndex: 3 }
    ]
    readonly property var itemsByKey: ({
        plastica: ["🧴", "🥤", "🍼"],
        carta:    ["📰", "📦", "📚"],
        vetro:    ["🍾", "🫙", "🥛"]
    })

    property int  done: 0
    property bool won: false
    property bool busy: false
    property int  mistakes: 0
    property int  lastBin: -1
    property var  binCounts: [0, 0, 0]
    property var  item: ({ emoji: "🧴", key: "plastica" })

    SoundBank { id: snd }

    function nextMsg() { return qsTr("Bravo! Continua così") }

    function goNext() {
        if (!won) return
        load()
    }

    function load() {
        done = 0
        won = false
        busy = false
        mistakes = 0
        lastBin = -1
        binCounts = [0, 0, 0]
        makeItem()
        card.goHome()
    }

    function makeItem() {
        var b = scaffold.bins[Math.floor(Math.random() * scaffold.bins.length)]
        var list = scaffold.itemsByKey[b.key]
        item = { emoji: list[Math.floor(Math.random() * list.length)], key: b.key }
    }

    function binCenter(i) {
        var bn = binRep.itemAt(i)
        if (!bn) return Qt.point(card.homeX, card.homeY)
        var p = bn.mapToItem(playArea, bn.width / 2, bn.height / 2)
        return Qt.point(p.x - card.width / 2, p.y - card.height / 2)
    }

    function accept(binIndex) {
        busy = true
        lastBin = binIndex
        snd.ok()
        leaveAnim.start()
    }

    function afterAccept() {
        var c = binCounts.slice()
        if (lastBin >= 0 && lastBin < c.length)
            c[lastBin] = (c[lastBin] || 0) + 1
        binCounts = c

        done += 1
        if (done >= perRound) {
            won = true
            busy = false
            snd.win()
            reward(3 - Math.min(2, mistakes), nextMsg())
            return
        }
        makeItem()
        card.goHome()
        busy = false
    }

    Component.onCompleted: load()

    // ---------- contenuto ----------
    Item {
        id: playArea
        anchors.fill: parent

        Row {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
            spacing: 10
            Repeater {
                model: scaffold.perRound
                Rectangle {
                    width: 16; height: 16; radius: 8
                    color: index < scaffold.done ? Theme.accent : Theme.boardLine
                }
            }
        }

        // ===== l'oggetto da spostare =====
        Item {
            id: card
            width: 150; height: 150
            scale: 1
            visible: !scaffold.won

            readonly property real homeX: (playArea.width - width) / 2
            readonly property real homeY: playArea.height * 0.30 - height / 2

            function goHome() { x = homeX; y = homeY; scale = 1 }

            onHomeXChanged: if (!dragArea.drag.active && !scaffold.busy) x = homeX
            onHomeYChanged: if (!dragArea.drag.active && !scaffold.busy) y = homeY

            Behavior on x { enabled: !dragArea.drag.active && !scaffold.busy; NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            Behavior on y { enabled: !dragArea.drag.active && !scaffold.busy; NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            Text {
                anchors.centerIn: parent
                text: scaffold.item.emoji
                font.pixelSize: 110
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                enabled: !scaffold.busy && !scaffold.won
                drag.target: card
                drag.minimumX: 0
                drag.maximumX: playArea.width - card.width
                drag.minimumY: 0
                drag.maximumY: playArea.height - card.height

                onReleased: {
                    var cx = card.x + card.width / 2
                    var cy = card.y + card.height / 2
                    var hit = -1
                    for (var k = 0; k < scaffold.bins.length; k++) {
                        var bn = binRep.itemAt(k)
                        if (!bn) continue
                        var p = bn.mapFromItem(playArea, cx, cy)
                        if (p.x >= 0 && p.x <= bn.width && p.y >= 0 && p.y <= bn.height) {
                            hit = k
                            break
                        }
                    }
                    if (hit >= 0 && scaffold.bins[hit].key === scaffold.item.key) {
                        scaffold.accept(hit)
                    } else {
                        if (hit >= 0) {
                            scaffold.mistakes += 1
                            snd.nope()
                        }
                        card.goHome()
                    }
                }
            }

            SequentialAnimation {
                id: leaveAnim
                ParallelAnimation {
                    NumberAnimation { target: card; property: "x"; to: scaffold.binCenter(scaffold.lastBin).x; duration: 260; easing.type: Easing.InQuad }
                    NumberAnimation { target: card; property: "y"; to: scaffold.binCenter(scaffold.lastBin).y; duration: 260; easing.type: Easing.InQuad }
                    NumberAnimation { target: card; property: "scale"; to: 0.15; duration: 260; easing.type: Easing.InQuad }
                }
                ScriptAction { script: scaffold.afterAccept() }
            }
        }

        // ===== i bidoni =====
        Row {
            id: binRow
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 }
            spacing: 40

            Repeater {
                id: binRep
                model: scaffold.bins

                Rectangle {
                    id: binRect
                    width: 200; height: 200
                    radius: 28
                    color: Theme.playColors[modelData.colorIndex]
                    opacity: 0.22
                    border.color: Theme.playColors[modelData.colorIndex]
                    border.width: 5

                    required property int index
                    required property var modelData
                    property int myCount: scaffold.binCounts[index] || 0

                    onMyCountChanged: if (myCount > 0) plop.restart()

                    SequentialAnimation {
                        id: plop
                        NumberAnimation { target: binRect; property: "scale"; from: 1.0; to: 1.06; duration: 110; easing.type: Easing.OutQuad }
                        NumberAnimation { target: binRect; property: "scale"; to: 1.0; duration: 110 }
                    }

                    Rectangle {   // pallina del colore del bidone, come indicatore
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -20
                        width: 84; height: 84; radius: 42
                        color: Theme.playColors[binRect.modelData.colorIndex]
                    }

                    Flow {
                        anchors {
                            left: parent.left; right: parent.right; bottom: parent.bottom
                            margins: 14
                        }
                        spacing: 6
                        Repeater {
                            model: binRect.myCount
                            Rectangle {
                                id: dot
                                width: 24; height: 24; radius: 12
                                color: Theme.playColors[binRect.modelData.colorIndex]
                                scale: 0
                                NumberAnimation {
                                    id: pop
                                    target: dot; property: "scale"
                                    from: 0; to: 1; duration: 240
                                    easing.type: Easing.OutBack
                                }
                                Component.onCompleted: pop.start()
                            }
                        }
                    }
                }
            }
        }
    }
}
