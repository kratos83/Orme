// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "La raccolta differenziata" - tre oggetti insieme sul tavolo, quattro bidoni
// colorati (plastica/gialla, carta/blu, vetro/verde, umido/arancione), ognuno
// con un'icona che ne identifica la categoria: si trascina ogni oggetto nel
// bidone giusto. Il gioco risponde a quello che fa il bambino: gli oggetti
// ondeggiano, si sollevano quando li si prende, il coperchio del bidone si
// apre quando ci si passa sopra, l'oggetto giusto viene "ingoiato" con una
// pioggia di scintille, quello sbagliato fa scuotere il bidone.
GameScaffold {
    id: scaffold
    title: qsTr("La raccolta differenziata")
    age: qsTr("3-5 anni")
    showNext: won

    onRestartRequested: load()
    onNextRequested: goNext()
    onWinFinished: goNext()

    readonly property int perRound: 9
    readonly property int tableSize: 3     // oggetti sul tavolo contemporaneamente

    // key = indice del bidone; colorIndex punta a Theme.playColors (i colori
    // reali della raccolta differenziata: plastica/giallo, carta/blu, vetro/verde,
    // umido/arancione); icon = simbolo mostrato sul bidone per riconoscere la categoria
    readonly property var bins: [
        { key: "plastica", colorIndex: 2, icon: "🧴" },
        { key: "carta",    colorIndex: 1, icon: "📄" },
        { key: "vetro",    colorIndex: 3, icon: "🍾" },
        { key: "umido",    colorIndex: 5, icon: "🍂" }
    ]
    readonly property var itemsByKey: ({
        plastica: ["🧴", "🥤", "🍼"],
        carta:    ["📰", "📦", "📚"],
        vetro:    ["🍾", "🫙", "🥛"],
        umido:    ["🍌", "🍎", "🥕"]
    })

    property int  done: 0
    property int  spawned: 0
    property bool won: false
    property int  mistakes: 0
    property int  hoverBin: -1                 // bidone sotto l'oggetto trascinato
    property var  binCounts: [0, 0, 0, 0]
    property var  slots: [null, null, null]    // oggetti sul tavolo (null = posto vuoto)

    SoundBank { id: snd }

    function nextMsg() { return qsTr("Bravo! Continua così") }

    function goNext() {
        if (!won) return
        load()
    }

    function newItem() {
        var b = scaffold.bins[Math.floor(Math.random() * scaffold.bins.length)]
        var list = scaffold.itemsByKey[b.key]
        spawned += 1
        return { emoji: list[Math.floor(Math.random() * list.length)], key: b.key }
    }

    function load() {
        done = 0
        spawned = 0
        won = false
        mistakes = 0
        hoverBin = -1
        binCounts = [0, 0, 0, 0]
        var s = []
        for (var k = 0; k < tableSize; k++) s.push(newItem())
        slots = s
    }

    // indice del bidone sotto il punto (x,y) di playArea, -1 se nessuno
    function binAt(x, y) {
        for (var k = 0; k < scaffold.bins.length; k++) {
            var bn = binRep.itemAt(k)
            if (!bn) continue
            var p = bn.mapFromItem(playArea, x, y)
            if (p.x >= 0 && p.x <= bn.width && p.y >= 0 && p.y <= bn.height)
                return k
        }
        return -1
    }

    // centro del bidone i, in coordinate di playArea
    function binCenter(i) {
        var bn = binRep.itemAt(i)
        if (!bn) return Qt.point(playArea.width / 2, playArea.height / 2)
        return bn.mapToItem(playArea, bn.width / 2, bn.height / 2)
    }

    function accepted(slot, binIndex) {
        var c = binCounts.slice()
        c[binIndex] = (c[binIndex] || 0) + 1
        binCounts = c

        done += 1
        var s = slots.slice()
        s[slot] = spawned < perRound ? newItem() : null
        slots = s

        if (done >= perRound) {
            won = true
            snd.win()
            reward(3 - Math.min(2, mistakes), nextMsg())
        }
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

        // ===== gli oggetti da spostare =====
        Repeater {
            model: scaffold.tableSize

            Item {
                id: card
                required property int index

                readonly property var itm: scaffold.slots[index]
                property bool flying: false
                readonly property bool lifted: dragArea.pressed || flying

                width: 130; height: 130
                visible: itm !== null && itm !== undefined && !scaffold.won
                z: (dragArea.drag.active || flying) ? 10 : 1

                readonly property real gap: 40
                readonly property real homeX: (playArea.width - (scaffold.tableSize * width + (scaffold.tableSize - 1) * gap)) / 2
                                              + index * (width + gap)
                readonly property real homeY: playArea.height * 0.30 - height / 2

                function goHome() { x = homeX; y = homeY }

                onHomeXChanged: if (!dragArea.drag.active && !flying) x = homeX
                onHomeYChanged: if (!dragArea.drag.active && !flying) y = homeY

                // nuovo oggetto sul tavolo: torna a casa e "spunta" ingrandendosi
                onItmChanged: {
                    goHome()
                    flying = false
                    rotation = 0
                    if (itm) spawn.restart()
                }

                Behavior on x { enabled: !dragArea.drag.active && !card.flying; NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                Behavior on y { enabled: !dragArea.drag.active && !card.flying; NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                Component.onCompleted: goHome()

                NumberAnimation { id: spawn; target: card; property: "scale"; from: 0; to: 1; duration: 320; easing.type: Easing.OutBack }

                // ombra: si allarga e si schiarisce quando l'oggetto e' sollevato
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height - 18
                    width: card.lifted ? 70 : 90; height: 18; radius: 9
                    color: "black"
                    opacity: card.lifted ? 0.10 : 0.22
                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Text {
                    id: face
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: card.lifted ? -14 : 0
                    text: card.itm ? card.itm.emoji : ""
                    font.pixelSize: 96
                    scale: card.lifted ? 1.25 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 120 } }
                }

                // ondeggia piano da fermo, per invitare a prenderlo
                SequentialAnimation {
                    running: card.visible && !dragArea.drag.active && !card.flying
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) card.rotation = 0
                    PauseAnimation { duration: card.index * 260 }
                    NumberAnimation { target: card; property: "rotation"; to: 5; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { target: card; property: "rotation"; to: -5; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { target: card; property: "rotation"; to: 0; duration: 700; easing.type: Easing.InOutSine }
                }

                // scossa quando sbagli bidone, prima di tornare a casa
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: face; property: "rotation"; to: -18; duration: 70 }
                    NumberAnimation { target: face; property: "rotation"; to: 18; duration: 110 }
                    NumberAnimation { target: face; property: "rotation"; to: -10; duration: 90 }
                    NumberAnimation { target: face; property: "rotation"; to: 0; duration: 70 }
                }

                function updateHover() {
                    if (dragArea.drag.active)
                        scaffold.hoverBin = scaffold.binAt(x + width / 2, y + height / 2)
                }
                onXChanged: updateHover()
                onYChanged: updateHover()

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    enabled: !card.flying && !scaffold.won
                    drag.target: card
                    drag.minimumX: 0
                    drag.maximumX: playArea.width - card.width
                    drag.minimumY: 0
                    drag.maximumY: playArea.height - card.height

                    onPressed: snd.tap()

                    onReleased: {
                        scaffold.hoverBin = -1
                        var hit = scaffold.binAt(card.x + card.width / 2, card.y + card.height / 2)
                        if (hit >= 0 && scaffold.bins[hit].key === card.itm.key) {
                            snd.ok()
                            var c = scaffold.binCenter(hit)
                            card.flying = true
                            toX.to = c.x - card.width / 2
                            toY.to = c.y - card.height / 2
                            leaveAnim.targetBin = hit
                            leaveAnim.start()
                        } else {
                            if (hit >= 0) {
                                scaffold.mistakes += 1
                                snd.nope()
                                binRep.itemAt(hit).shake()
                                shake.restart()
                            }
                            card.goHome()
                        }
                    }
                }

                SequentialAnimation {
                    id: leaveAnim
                    property int targetBin: -1
                    ParallelAnimation {
                        NumberAnimation { id: toX; target: card; property: "x"; duration: 260; easing.type: Easing.InQuad }
                        NumberAnimation { id: toY; target: card; property: "y"; duration: 260; easing.type: Easing.InQuad }
                        NumberAnimation { target: card; property: "scale"; to: 0.15; duration: 260; easing.type: Easing.InQuad }
                        NumberAnimation { target: card; property: "rotation"; to: 25; duration: 260 }
                    }
                    ScriptAction {
                        script: {
                            binRep.itemAt(leaveAnim.targetBin).swallow()
                            scaffold.accepted(card.index, leaveAnim.targetBin)
                        }
                    }
                }
            }
        }

        // ===== i bidoni =====
        Row {
            id: binRow
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 }
            spacing: 24

            Repeater {
                id: binRep
                model: scaffold.bins

                Rectangle {
                    id: binRect
                    width: 200; height: 200
                    radius: 28
                    color: Theme.playColors[modelData.colorIndex]
                    border.color: Theme.playColors[modelData.colorIndex]
                    border.width: 5

                    required property int index
                    required property var modelData
                    readonly property bool open: scaffold.hoverBin === index
                    property int myCount: scaffold.binCounts[index] || 0

                    opacity: open ? 1.0 : 0.78
                    scale: open ? 1.07 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                    signal sparkle()

                    function shake() { wobble.restart() }
                    function swallow() { chew.restart(); sparkle(); }

                    SequentialAnimation {
                        id: wobble
                        NumberAnimation { target: binRect; property: "rotation"; to: -7; duration: 60 }
                        NumberAnimation { target: binRect; property: "rotation"; to: 7; duration: 100 }
                        NumberAnimation { target: binRect; property: "rotation"; to: -4; duration: 80 }
                        NumberAnimation { target: binRect; property: "rotation"; to: 0; duration: 60 }
                    }

                    // l'icona "ingoia": si gonfia e si sgonfia
                    SequentialAnimation {
                        id: chew
                        NumberAnimation { target: badge; property: "scale"; to: 1.3; duration: 100; easing.type: Easing.OutQuad }
                        NumberAnimation { target: badge; property: "scale"; to: 0.9; duration: 100 }
                        NumberAnimation { target: badge; property: "scale"; to: 1.0; duration: 100 }
                    }

                    // coperchio: si apre quando l'oggetto e' sopra il bidone
                    Rectangle {
                        id: lid
                        x: -6; y: -18
                        width: parent.width + 12; height: 26
                        radius: 10
                        color: Qt.darker(Theme.playColors[binRect.modelData.colorIndex], 1.3)
                        transformOrigin: Item.BottomLeft
                        rotation: binRect.open ? -30 : 0
                        Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                        Rectangle {   // maniglia
                            anchors.centerIn: parent
                            width: 44; height: 8; radius: 4
                            color: Qt.lighter(parent.color, 1.5)
                        }
                    }

                    Rectangle {   // pallina del colore del bidone, con l'icona della categoria
                        id: badge
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -20
                        width: 84; height: 84; radius: 42
                        color: Theme.playColors[binRect.modelData.colorIndex]
                        border.color: "white"
                        border.width: 3

                        Text {
                            anchors.centerIn: parent
                            text: binRect.modelData.icon
                            font.pixelSize: 46
                        }
                    }

                    // pioggia di scintille quando l'oggetto e' nel bidone giusto
                    Repeater {
                        model: 7
                        Text {
                            id: spark
                            required property int index
                            text: index % 2 ? "⭐" : "✨"
                            font.pixelSize: 26
                            x: binRect.width / 2 - width / 2
                            y: binRect.height / 2 - height / 2
                            opacity: 0
                            z: 5

                            Connections {
                                target: binRect
                                function onSparkle() { fly.restart() }
                            }
                            ParallelAnimation {
                                id: fly
                                NumberAnimation { target: spark; property: "x"; from: binRect.width / 2 - 13
                                                  to: binRect.width / 2 - 13 + Math.cos(spark.index * 0.9) * 110
                                                  duration: 600; easing.type: Easing.OutQuad }
                                NumberAnimation { target: spark; property: "y"; from: binRect.height / 2 - 13
                                                  to: binRect.height / 2 - 13 - 40 - Math.abs(Math.sin(spark.index * 0.9)) * 100
                                                  duration: 600; easing.type: Easing.OutQuad }
                                SequentialAnimation {
                                    NumberAnimation { target: spark; property: "opacity"; to: 1; duration: 80 }
                                    NumberAnimation { target: spark; property: "opacity"; to: 0; duration: 520 }
                                }
                            }
                        }
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
                                border.color: "white"
                                border.width: 2
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
