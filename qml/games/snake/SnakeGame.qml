// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Il serpente" - come lo Snake del Nokia: il serpente avanza da solo,
// un passo alla volta; toccando le frecce lo si guida (si cambia solo la
// direzione, non si comanda il passo). Mangia le mele e cresce; se tocca
// il muro o se stesso si torna alla partenza. Pianificare i movimenti ed
// evitare gli ostacoli (anche il proprio corpo).
MiniGame {
    id: g
    title: qsTr("Il serpente")
    age: qsTr("4-5 anni")
    levelCount: 6

    readonly property int cols: 6
    readonly property int rows: 6

    property var snake: []     // {c, r}; indice 0 = testa
    property var apples: []    // {c, r}
    property int  dir: 3       // direzione attuale: 0 su, 1 giu, 2 sinistra, 3 destra
    property bool busy: false  // vero durante il "riprova" dopo uno scontro
    readonly property int stepInterval: Math.max(420, 750 - levelIndex * 40)

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function randInt(n) { return Math.floor(Math.random() * n) }

    function cellFree(c, r, list) {
        for (var k = 0; k < list.length; k++)
            if (list[k].c === c && list[k].r === r) return false
        return true
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        busy = false
        dir = 3
        var startC = Math.floor(cols / 2), startR = Math.floor(rows / 2)
        snake = [{ c: startC, r: startR }]
        var appleCount = Math.min(3 + Math.floor(i / 2), 5)
        var a = []
        while (a.length < appleCount) {
            var c = randInt(cols), r = randInt(rows)
            if (cellFree(c, r, snake) && cellFree(c, r, a)) a.push({ c: c, r: r })
        }
        apples = a
    }

    function crash() {
        busy = true
        snd.nope()
        wrong()
        oops()
        retryTimer.restart()
    }

    Timer { id: retryTimer; interval: 1300; onTriggered: g.load(g.levelIndex) }

    // il tocco cambia solo la direzione: il passo lo fa da solo il timer.
    // non si puo' invertire di colpo sul proprio collo (su<->giu, sx<->dx)
    function steer(d) {
        if (busy || won) return
        var opposite = { 0: 1, 1: 0, 2: 3, 3: 2 }
        if (snake.length > 1 && d === opposite[dir]) return
        dir = d
    }

    Timer {
        id: ticker
        interval: g.stepInterval
        running: !g.busy && !g.won
        repeat: true
        onTriggered: g.move(g.dir)
    }

    function move(dir) {
        if (busy || won || snake.length === 0) return
        var head = snake[0]
        var nc = head.c, nr = head.r
        if (dir === 0) nr -= 1
        else if (dir === 1) nr += 1
        else if (dir === 2) nc -= 1
        else nc += 1

        if (nc < 0 || nc >= cols || nr < 0 || nr >= rows) { crash(); return }

        var appleIdx = -1
        for (var k = 0; k < apples.length; k++)
            if (apples[k].c === nc && apples[k].r === nr) { appleIdx = k; break }
        var grows = appleIdx !== -1

        // la coda lascia libera la sua casella in questo stesso passo,
        // a meno che il serpente non stia crescendo
        var body = grows ? snake : snake.slice(0, snake.length - 1)
        for (var b = 0; b < body.length; b++)
            if (body[b].c === nc && body[b].r === nr) { crash(); return }

        var ns = snake.slice()
        ns.unshift({ c: nc, r: nr })
        if (!grows) ns.pop()
        snake = ns

        if (grows) {
            var na = apples.slice()
            na.splice(appleIdx, 1)
            apples = na
            if (apples.length === 0) { snd.win(); win(); return }
            snd.ok()
        } else {
            snd.tap()
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Item {
            id: field
            anchors { top: parent.top; left: parent.left; right: parent.right; bottom: padArea.top; margins: 8 }

            readonly property real cell: Math.min(width / g.cols, height / g.rows)

            Rectangle {
                id: floor
                width: field.cell * g.cols
                height: field.cell * g.rows
                anchors.centerIn: parent
                radius: 24
                color: Theme.boardFill
                border.color: Theme.boardLine
                border.width: 4
                clip: true

                // linee verticali della griglia
                Row {
                    Repeater {
                        model: g.cols
                        Rectangle {
                            width: field.cell; height: floor.height
                            color: "transparent"
                            border.color: Theme.boardLine
                            border.width: 1
                        }
                    }
                }
                // linee orizzontali della griglia
                Column {
                    Repeater {
                        model: g.rows
                        Rectangle {
                            width: floor.width; height: field.cell
                            color: "transparent"
                            border.color: Theme.boardLine
                            border.width: 1
                        }
                    }
                }

                // tocco diretto sul campo: sterza verso il lato toccato
                // rispetto al centro (su/giu/sinistra/destra)
                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        var dx = mouse.x - floor.width / 2
                        var dy = mouse.y - floor.height / 2
                        if (Math.abs(dx) > Math.abs(dy))
                            g.steer(dx > 0 ? 3 : 2)
                        else
                            g.steer(dy > 0 ? 1 : 0)
                    }
                }

                Repeater {   // mele
                    model: g.apples
                    Text {
                        required property var modelData
                        x: modelData.c * field.cell
                        y: modelData.r * field.cell
                        width: field.cell; height: field.cell
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "🍎"
                        font.pixelSize: field.cell * 0.6
                    }
                }

                Repeater {   // corpo (senza la testa)
                    model: g.snake.length > 1 ? g.snake.slice(1) : []
                    Rectangle {
                        required property var modelData
                        width: field.cell * 0.8; height: width
                        radius: width * 0.35
                        x: modelData.c * field.cell + (field.cell - width) / 2
                        y: modelData.r * field.cell + (field.cell - width) / 2
                        color: Theme.accent
                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                    }
                }

                Rectangle {   // testa
                    id: head
                    width: field.cell * 0.9; height: width
                    radius: width * 0.35
                    x: (g.snake.length ? g.snake[0].c : 0) * field.cell + (field.cell - width) / 2
                    y: (g.snake.length ? g.snake[0].r : 0) * field.cell + (field.cell - width) / 2
                    color: Theme.accentDark
                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                    Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

                    Row {
                        anchors.centerIn: parent
                        spacing: parent.width * 0.22
                        Repeater {
                            model: 2
                            Rectangle { width: head.width * 0.16; height: width; radius: width / 2; color: "white" }
                        }
                    }
                }
            }
        }

        Item {
            id: padArea
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
            width: pad.implicitWidth
            height: pad.implicitHeight

            DirectionPad {
                id: pad
                active: !g.busy && !g.won
                onMoved: (d) => g.steer(d)
            }
        }
    }
}
