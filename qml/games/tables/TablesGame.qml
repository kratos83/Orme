// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Tabelline: si sceglie il numero (2-10). In alto nuotano i pesci con i
// multipli, sotto ci sono dieci conchiglie (2x1, 2x2, ...): ogni numero va
// nella sua. Si puo' trascinare il pesce sulla conchiglia giusta, oppure
// toccare i pesci in ordine crescente e volano da soli al loro posto.
// Sbagliare costa una vita; a zero vite il livello ricomincia.
MiniGame {
    id: g
    title: qsTr("Tabellina del ") + g.table
    scenery: "mare"
    age: qsTr("8-9 anni")
    levelCount: 6

    property int table: 2
    property bool started: false
    property var multiples: []
    property int lives: 5
    property var placed: []       // 10 bool: numero assegnato alla conchiglia
    property var shown: []        // 10 bool: numero gia' arrivato (a volo finito)
    property int hoverShell: -1   // conchiglia sotto il pesce trascinato

    readonly property string art: "qrc:/qt/qml/Orme/assets/art/"

    SoundBank { id: snd }

    // un pesce che "vola" fino alla sua conchiglia e sparisce (un inline
    // component ha un suo scope di id separato: non puo' vedere "g", quindi
    // segnala solo il proprio arrivo con un segnale)
    component FishFlight: AppIcon {
        id: ff
        name: "fish"
        size: 56
        property real destX: x
        property real destY: y
        signal arrived()
        NumberAnimation on x { to: ff.destX; duration: 460; easing.type: Easing.InOutQuad }
        NumberAnimation on y { to: ff.destY; duration: 460; easing.type: Easing.InQuad }
        NumberAnimation on scale { from: 1.2; to: 0.5; duration: 460; easing.type: Easing.InQuad }
        NumberAnimation on rotation { from: 0; to: 360; duration: 460 }
        Timer { interval: 470; running: true; onTriggered: ff.arrived() }
    }
    Component { id: fishFlightComp; FishFlight {} }

    onBuildLevel: (i) => load(i)

    function shuffle(a) {
        var r = a.slice()
        for (var k = r.length - 1; k > 0; k--) {
            var j = Math.floor(Math.random() * (k + 1))
            var t = r[k]; r[k] = r[j]; r[j] = t
        }
        return r
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        lives = 5
        hoverShell = -1
        var arr = [], no = []
        for (var k = 1; k <= 10; k++) { arr.push(k * table); no.push(false) }
        placed = no
        shown = no.slice()
        multiples = shuffle(arr)
    }

    function setFlag(list, k) {
        var a = list.slice()
        a[k] = true
        return a
    }

    // indice della conchiglia sotto il punto (coordinate di "item"), o -1
    function shellAt(item, x, y) {
        for (var k = 0; k < shellRep.count; k++) {
            var sh = shellRep.itemAt(k)
            if (!sh) continue
            var p = sh.mapFromItem(item, x, y)
            if (p.x >= 0 && p.x <= sh.width && p.y >= -12 && p.y <= sh.height) return k
        }
        return -1
    }

    function launchFish(fishItem, k) {
        var target = shellRep.itemAt(k)
        var start = fishItem.mapToItem(flightLayer, fishItem.width / 2 - 28, fishItem.height / 2 - 28)
        var end = target.mapToItem(flightLayer, target.width / 2 - 28, target.width / 2 - 28)
        var obj = fishFlightComp.createObject(flightLayer, { x: start.x, y: start.y, destX: end.x, destY: end.y })
        obj.arrived.connect(function () {
            if (g.placed[k]) g.shown = g.setFlag(g.shown, k)
            obj.destroy()
        })
    }

    function checkWin() {
        if (placed.every((p) => p)) { snd.win(); win() }
    }

    function fail(fishItem) {
        snd.nope()
        fishItem.shakeMe()
        lives -= 1
        wrong()
        if (lives <= 0) { oops(); load(levelIndex) }
    }

    // tocco: vale solo il multiplo piu' piccolo ancora da sistemare
    function tapFish(fishItem) {
        if (won || !started) return
        var next = placed.indexOf(false)
        if (fishItem.value !== (next + 1) * table) { fail(fishItem); return }
        snd.ok()
        launchFish(fishItem, next)
        placed = setFlag(placed, next)
        checkWin()
    }

    // trascinamento: il numero deve finire nella sua conchiglia, in qualunque ordine
    function dropFish(fishItem, k) {
        if (won || !started || k < 0 || placed[k]) return
        if (fishItem.value !== (k + 1) * table) { fail(fishItem); return }
        snd.ok()
        placed = setFlag(placed, k)
        shown = setFlag(shown, k)
        checkWin()
    }

    // ---------- contenuto ----------
    Item {
        id: board
        anchors.fill: parent
        visible: g.started

        Row {
            id: hearts
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            spacing: 6
            Repeater {
                model: 5
                AppIcon {
                    required property int index
                    name: index < g.lives ? "heart-red" : "heart-white"
                    size: 34
                }
            }
        }

        Text {
            id: hint
            anchors { top: hearts.bottom; topMargin: 4 }
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: qsTr("Metti ogni numero nella sua conchiglia: trascina i pesci, o toccali in ordine")
            font.pixelSize: 20
            color: Theme.text
        }

        // ===== i pesci con i numeri =====
        Item {
            id: pond
            z: 2          // il pesce trascinato passa sopra le conchiglie
            anchors { top: hint.bottom; bottom: shelf.top; left: parent.left; right: parent.right }

            Grid {
                id: fishGrid
                anchors.centerIn: parent
                readonly property int perRow: pond.width >= 640 ? 5 : 4
                readonly property real fishSize: Math.max(60, Math.min(104,
                    (pond.height - 24) / Math.ceil(10 / perRow), (pond.width - 24) / perRow - 22))
                columns: perRow
                rowSpacing: 12
                columnSpacing: 22

                Repeater {
                    model: g.multiples
                    Item {
                        id: spot
                        required property int modelData
                        width: fishGrid.fishSize; height: width
                        z: fma.drag.active ? 10 : 0

                        Rectangle {
                            id: fish
                            readonly property int value: spot.modelData
                            width: spot.width; height: spot.height; radius: width / 2
                            visible: !g.placed[value / g.table - 1]
                            color: Theme.dirLeft   // arancio: il pesce azzurro risalta
                            border.color: "white"
                            border.width: 4
                            scale: fma.pressed ? 1.1 : 1
                            Behavior on scale { NumberAnimation { duration: 80 } }

                            function shakeMe() { shakeAnim.start() }
                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: fish; property: "rotation"; to: -14; duration: 60 }
                                NumberAnimation { target: fish; property: "rotation"; to: 14; duration: 60 }
                                NumberAnimation { target: fish; property: "rotation"; to: 0; duration: 60 }
                            }

                            Candy {}
                            Column {
                                anchors.centerIn: parent
                                spacing: -4
                                AppIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "fish"; size: fish.width * 0.46 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: fish.value; font.pixelSize: fish.width * 0.3; font.bold: true; color: "white" }
                            }

                            MouseArea {
                                id: fma
                                property bool dragged: false
                                anchors.fill: parent
                                enabled: !g.won
                                drag.target: fish
                                onPressed: dragged = false
                                onPositionChanged: {
                                    if (!drag.active) return
                                    dragged = true
                                    g.hoverShell = g.shellAt(fish, fish.width / 2, fish.height / 2)
                                }
                                onReleased: {
                                    var target = dragged ? g.shellAt(fish, fish.width / 2, fish.height / 2) : -1
                                    g.hoverShell = -1
                                    fish.x = 0; fish.y = 0
                                    // per ultimo: puo' ricaricare il livello
                                    if (dragged) g.dropFish(fish, target)
                                    else g.tapFish(fish)
                                }
                                onCanceled: { g.hoverShell = -1; fish.x = 0; fish.y = 0 }
                            }
                        }
                    }
                }
            }
        }

        // ===== le conchiglie, una per ogni moltiplicazione =====
        Grid {
            id: shelf
            // una fila sola sugli schermi larghi, due file su quelli stretti
            readonly property int perRow: board.width >= 900
                || (board.width >= 600 && board.width > board.height * 1.2) ? 10 : 5
            readonly property real cell: Math.max(56, Math.min(112,
                (board.width - (perRow - 1) * columnSpacing - 8) / perRow))
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 70 }
            columns: perRow
            columnSpacing: 4
            rowSpacing: 4

            Repeater {
                id: shellRep
                model: 10
                Item {
                    id: shellSlot
                    required property int index
                    readonly property bool full: g.shown[index] === true
                    width: shelf.cell; height: shelf.cell + 28

                    Item {
                        id: shellArt
                        width: shelf.cell; height: width
                        scale: g.hoverShell === shellSlot.index ? 1.18 : 1
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                        Image {
                            anchors.fill: parent
                            source: g.art + (shellSlot.full ? "shell-full" : "shell-empty") + ".png"
                            mipmap: true
                        }
                        Text {   // il numero nella perla
                            x: parent.width / 2 - width / 2
                            y: parent.height * 0.51 - height / 2
                            text: shellSlot.full ? (shellSlot.index + 1) * g.table : "?"
                            font.pixelSize: parent.width * 0.28
                            font.bold: true
                            color: shellSlot.full ? Theme.title : "#D9A9B8"
                        }
                        SequentialAnimation {
                            id: pop
                            NumberAnimation { target: shellArt; property: "scale"; to: 1.28; duration: 130 }
                            NumberAnimation { target: shellArt; property: "scale"; to: 1; duration: 160; easing.type: Easing.OutBack }
                        }
                    }
                    onFullChanged: if (full) pop.restart()

                    Rectangle {   // quale moltiplicazione va qui
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        width: Math.min(parent.width - 6, sum.implicitWidth + 18)
                        height: 26; radius: 13
                        color: "white"
                        border.color: shellSlot.full ? "#FFB300" : "#F48FB1"
                        border.width: 2
                        Text {
                            id: sum
                            anchors.centerIn: parent
                            text: g.table + " × " + (shellSlot.index + 1)
                            font.pixelSize: Math.min(17, shelf.cell * 0.18)
                            font.bold: true
                            color: Theme.text
                        }
                    }
                }
            }
        }

        // strato dove "volano" i pesci toccati verso le conchiglie
        Item { id: flightLayer; anchors.fill: parent; z: 50 }
    }

    // ---------- schermata di scelta della tabellina ----------
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        visible: !g.started

        Column {
            anchors.centerIn: parent
            spacing: 30

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Scegli la tabellina")
                font.pixelSize: 30
                font.bold: true
                color: Theme.text
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 5
                rowSpacing: 14
                columnSpacing: 14
                Repeater {
                    model: [2, 3, 4, 5, 6, 7, 8, 9, 10]
                    Rectangle {
                        id: chip
                        Candy {}
                        required property int modelData
                        width: 74; height: 74; radius: 20
                        color: g.table === modelData ? Theme.accent : Theme.panel
                        border.color: Theme.boardLine
                        border.width: 3
                        scale: chipMa.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text {
                            anchors.centerIn: parent
                            text: chip.modelData
                            font.pixelSize: 30
                            font.bold: true
                            color: g.table === chip.modelData ? "white" : Theme.text
                        }
                        MouseArea { id: chipMa; anchors.fill: parent; onClicked: g.table = chip.modelData }
                    }
                }
            }

            Rectangle {
                Candy {}
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200; height: 76; radius: 22
                color: Theme.accent
                scale: startMa.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }
                Text { anchors.centerIn: parent; text: qsTr("Inizia"); font.pixelSize: 26; font.bold: true; color: "white" }
                MouseArea { id: startMa; anchors.fill: parent; onClicked: { g.started = true; g.buildLevel(0) } }
            }
        }
    }
}
