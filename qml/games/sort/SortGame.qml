// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Metti a posto" - il concetto di CLASSIFICARE / condizione "se... allora...".
// Un oggetto al centro: il bambino lo trascina nel cesto giusto. Quando entra,
// nel cesto si aggiunge una pallina (che compare con un saltino) e il cesto
// fa un rimbalzo. 3 turni con regole diverse: per colore, grandezza, tipo.
GameScaffold {
    id: scaffold
    title: qsTr("Metti a posto")
    age: qsTr("3-4 anni")
    showNext: won

    onRestartRequested: load(roundIndex)
    onNextRequested: goNext()
    onWinFinished: goNext()

    readonly property int roundCount: 3
    readonly property int perRound: 6

    readonly property var animals: ["🐶", "🐱", "🐰", "🐻", "🦊", "🐸", "🐵", "🐷"]
    readonly property var fruits:  ["🍎", "🍌", "🍓", "🍇", "🍊", "🍉", "🍐", "🍒"]

    property int  roundIndex: 0
    property int  done: 0
    property bool won: false
    property bool busy: false          // vero mentre un pezzo "entra" nel cesto
    property int  mistakes: 0
    property int  lastBin: -1          // indice del cesto che ha appena ricevuto
    property var  bins: [0, 1, 2]
    property var  binCounts: [0, 0, 0] // quante palline ha ogni cesto
    property var  item: ({ kind: "circle", colorIndex: 0, size: 120, key: 0 })

    SoundBank { id: snd }

    function nextMsg() {
        return qsTr("Sei al livello ") + (((roundIndex + 1) % roundCount) + 1)
    }
    function goNext() {
        if (!won) return
        load(roundIndex + 1)
    }

    function load(i) {
        roundIndex = ((i % roundCount) + roundCount) % roundCount
        done = 0
        won = false
        busy = false
        mistakes = 0
        lastBin = -1
        if (roundIndex === 0)      bins = [0, 1, 2]
        else if (roundIndex === 1) bins = ["big", "small"]
        else                       bins = ["animal", "fruit"]
        var z = []
        for (var b = 0; b < bins.length; b++) z.push(0)
        binCounts = z
        makeItem()
        card.goHome()
    }

    function makeItem() {
        if (roundIndex === 0) {
            var k = Math.floor(Math.random() * 3)
            item = { kind: "circle", colorIndex: k, size: 120, key: k }
        } else if (roundIndex === 1) {
            var big = Math.random() < 0.5
            item = { kind: "circle",
                     colorIndex: Math.floor(Math.random() * 6),
                     size: big ? 156 : 76,
                     key: big ? "big" : "small" }
        } else {
            var animal = Math.random() < 0.5
            var list = animal ? animals : fruits
            item = { kind: "emoji",
                     emoji: list[Math.floor(Math.random() * list.length)],
                     size: 120,
                     key: animal ? "animal" : "fruit" }
        }
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
        // aggiungi la pallina nel cesto giusto
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
        card.goHome()      // istantaneo: busy e' ancora true
        busy = false
    }

    Component.onCompleted: load(0)

    // ---------- contenuto ----------
    Item {
        id: playArea
        anchors.fill: parent

        // progresso: 6 pallini
        Row {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
            spacing: 12
            Repeater {
                model: scaffold.perRound
                Rectangle {
                    width: 18; height: 18; radius: 9
                    color: index < scaffold.done ? Theme.accent : Theme.boardLine
                }
            }
        }

        // ===== l'oggetto da spostare =====
        Item {
            id: card
            width: 168; height: 168
            scale: 1
            visible: !scaffold.won

            readonly property real homeX: (playArea.width - width) / 2
            readonly property real homeY: playArea.height * 0.30 - height / 2

            function goHome() { x = homeX; y = homeY; scale = 1 }

            onHomeXChanged: if (!dragArea.drag.active && !scaffold.busy) x = homeX
            onHomeYChanged: if (!dragArea.drag.active && !scaffold.busy) y = homeY

            Behavior on x { enabled: !dragArea.drag.active && !scaffold.busy; NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            Behavior on y { enabled: !dragArea.drag.active && !scaffold.busy; NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            // forma "cerchio"
            Rectangle {
                anchors.centerIn: parent
                visible: scaffold.item.kind === "circle"
                width: scaffold.item.size
                height: width
                radius: width / 2
                color: Theme.playColors[scaffold.item.colorIndex]
            }
            // forma "emoji"
            Text {
                anchors.centerIn: parent
                visible: scaffold.item.kind === "emoji"
                text: scaffold.item.emoji || ""
                font.pixelSize: scaffold.item.size
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
                    if (hit >= 0 && scaffold.bins[hit] === scaffold.item.key) {
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

            // "entra nel cesto": vola verso il cesto e rimpicciolisce
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

        // ===== i cesti =====
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
                    color: Theme.panel
                    border.color: Theme.boardLine
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

                    // etichetta del cesto secondo il turno (un po' in alto)
                    Rectangle {   // colore
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -20
                        visible: scaffold.roundIndex === 0
                        width: 84; height: 84; radius: 42
                        color: Theme.playColors[binRect.modelData === undefined ? 0 : binRect.modelData]
                    }
                    Rectangle {   // grandezza
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -20
                        visible: scaffold.roundIndex === 1
                        width: binRect.modelData === "big" ? 112 : 48
                        height: width; radius: width / 2
                        color: Theme.boardLine
                    }
                    Text {        // tipo
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -14
                        visible: scaffold.roundIndex === 2
                        text: binRect.modelData === "animal" ? "🐾" : "🍽️"
                        font.pixelSize: 84
                    }

                    // le palline raccolte, in basso nel cesto
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
                                color: scaffold.roundIndex === 0
                                       ? Theme.playColors[binRect.modelData]
                                       : Theme.accent
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
