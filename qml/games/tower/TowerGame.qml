import QtQuick
import Orme

// "Costruisci la torre" - costruzioni a blocchi: immaginazione spaziale e
// pazienza. In alto a sinistra il modellino da copiare; il bambino trascina
// i blocchi colorati dal vassoio nella torre, dal basso verso l'alto.
MiniGame {
    id: g
    title: qsTr("Costruisci la torre")
    age: qsTr("3-4 anni")
    levelCount: 6

    readonly property var counts: [3, 3, 4, 4, 5, 5]

    property int blockCount: 3
    property var order: []        // colori, index 0 = base della torre
    property var filled: []       // bool per posizione
    property var trayColors: []   // colori ancora nel vassoio

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function shuffle(a) {
        var r = a.slice()
        for (var i = r.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1))
            var t = r[i]; r[i] = r[j]; r[j] = t
        }
        return r
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        blockCount = counts[i % counts.length]
        var palette = shuffle(Theme.playColors.slice()).slice(0, blockCount)
        order = palette
        var f = []
        for (var k = 0; k < blockCount; k++) f.push(false)
        filled = f
        trayColors = shuffle(palette.slice())
    }

    function nextEmpty() {
        for (var i = 0; i < filled.length; i++)
            if (!filled[i]) return i
        return -1
    }

    // slotIndex: -1 se il pezzo non e' stato rilasciato su nessuno slot.
    // Ritorna true se il pezzo e' stato agganciato (e quindi rimosso dal
    // vassoio): in quel caso non va piu' toccato, il delegate sparisce.
    function drop(color, slotIndex) {
        if (slotIndex < 0) return false
        var ne = nextEmpty()
        if (order[slotIndex] === color && slotIndex === ne) {
            var f = filled.slice(); f[slotIndex] = true; filled = f
            trayColors = trayColors.filter(function (c) { return c !== color })
            snd.ok()
            if (trayColors.length === 0) { snd.win(); win() }
            return true
        } else if (order[slotIndex] !== color) {
            g.mistakes += 1
            snd.nope()
        }
        // colore giusto ma non e' il turno: il pezzo torna semplicemente a casa
        return false
    }

    // ---------- contenuto ----------
    Item {
        id: playArea
        anchors.fill: parent

        // ===== modellino di riferimento =====
        Rectangle {
            id: modelFrame
            anchors { left: parent.left; top: parent.top; margins: 14 }
            width: 60; height: 210
            radius: 14
            color: Theme.panel
            border.color: Theme.boardLine
            border.width: 3

            Column {
                anchors.centerIn: parent
                spacing: 4
                Repeater {
                    model: g.blockCount
                    Rectangle {
                        required property int index
                        width: 40; height: 40; radius: 8
                        color: g.order[g.blockCount - 1 - index]
                    }
                }
            }
        }

        // ===== la torre da costruire =====
        Column {
            id: stack
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 14
            spacing: 6

            Repeater {
                id: slotRep
                model: g.blockCount
                Rectangle {
                    id: slotRect
                    required property int index
                    readonly property int slotIndex: g.blockCount - 1 - index
                    readonly property bool full: g.filled[slotIndex] === true

                    width: 110; height: 110
                    radius: 18
                    color: full ? g.order[slotIndex] : "transparent"
                    border.color: Theme.boardLine
                    border.width: full ? 0 : 4

                    onFullChanged: if (full) pop.restart()
                    SequentialAnimation {
                        id: pop
                        NumberAnimation { target: slotRect; property: "scale"; from: 0.7; to: 1.08; duration: 140; easing.type: Easing.OutBack }
                        NumberAnimation { target: slotRect; property: "scale"; to: 1.0; duration: 120 }
                    }
                }
            }
        }

        // ===== vassoio dei blocchi =====
        Repeater {
            model: g.trayColors

            Rectangle {
                id: piece
                required property int index
                required property var modelData

                width: 100; height: 100
                radius: 16
                color: modelData
                border.color: Theme.boardLine
                border.width: 2

                readonly property int trayCount: g.trayColors.length
                readonly property real rowW: trayCount * width + (trayCount - 1) * 20
                readonly property real homeX: (playArea.width - rowW) / 2 + index * (width + 20)
                readonly property real homeY: playArea.height - height - 24

                function goHome() { x = homeX; y = homeY }

                onHomeXChanged: if (!dragArea.drag.active) goHome()
                onHomeYChanged: if (!dragArea.drag.active) goHome()

                Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
                Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

                Component.onCompleted: goHome()

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    enabled: !g.won
                    drag.target: piece
                    drag.minimumX: 0
                    drag.maximumX: playArea.width - piece.width
                    drag.minimumY: 0
                    drag.maximumY: playArea.height - piece.height

                    onReleased: {
                        var cx = piece.x + piece.width / 2
                        var cy = piece.y + piece.height / 2
                        var hit = -1
                        for (var v = 0; v < g.blockCount; v++) {
                            var sl = slotRep.itemAt(v)
                            if (!sl) continue
                            var p = sl.mapFromItem(playArea, cx, cy)
                            if (p.x >= 0 && p.x <= sl.width && p.y >= 0 && p.y <= sl.height) {
                                hit = sl.slotIndex
                                break
                            }
                        }
                        if (!g.drop(piece.modelData, hit))
                            piece.goHome()
                    }
                }
            }
        }
    }
}
