// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Tabelline: si sceglie il numero (2-10), poi si toccano i pesci con i
// multipli in ordine crescente (2x1, 2x2, 2x3, ...). Sbagliare costa una
// vita; a zero vite il livello ricomincia.
MiniGame {
    id: g
    title: qsTr("Tabellina del ") + g.table
    age: qsTr("8-9 anni")
    levelCount: 6

    property int table: 2
    property bool started: false
    property var multiples: []
    property int nextIndex: 1     // prossimo moltiplicatore atteso (1..10)
    property int lives: 5
    property int shellCount: 0    // quanti pesci sono già nella conchiglia

    SoundBank { id: snd }

    // un pesce che "vola" dalla sua posizione fino alla conchiglia e sparisce
    // (un inline component ha un suo scope di id separato: non può vedere
    // "g" o "shell", quindi segnala solo il proprio arrivo con un segnale)
    component FishFlight: Text {
        id: ff
        text: "🐟"
        font.pixelSize: 40
        property real destX: x
        property real destY: y
        signal arrived()
        NumberAnimation on x { to: ff.destX; duration: 420; easing.type: Easing.InQuad }
        NumberAnimation on y { to: ff.destY; duration: 420; easing.type: Easing.InQuad }
        NumberAnimation on scale { from: 1; to: 0.25; duration: 420; easing.type: Easing.InQuad }
        NumberAnimation on rotation { from: 0; to: 360; duration: 420 }
        Timer { interval: 430; running: true; onTriggered: ff.arrived() }
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
        nextIndex = 1
        shellCount = 0
        var arr = []
        for (var k = 1; k <= 10; k++) arr.push(k * table)
        multiples = shuffle(arr)
    }

    function launchFish(fishItem) {
        var start = fishItem.mapToItem(flightLayer, fishItem.width / 2 - 20, fishItem.height / 2 - 20)
        var end = shell.mapToItem(flightLayer, shell.width / 2 - 20, shell.height / 2 - 20)
        var obj = fishFlightComp.createObject(flightLayer, { x: start.x, y: start.y, destX: end.x, destY: end.y })
        obj.arrived.connect(function () { g.shellCount += 1; obj.destroy() })
    }

    function tapFish(fishItem) {
        if (won || !started) return
        var value = fishItem.modelData
        if (value === nextIndex * table) {
            snd.ok()
            launchFish(fishItem)
            nextIndex += 1
            multiples = multiples.filter((v) => v !== value)
            if (nextIndex > 10) { snd.win(); win() }
        } else {
            snd.nope()
            fishItem.shakeMe()
            lives -= 1
            wrong()
            if (lives <= 0) { oops(); load(levelIndex) }
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent
        visible: g.started

        Row {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            spacing: 6
            Repeater {
                model: 5
                Text {
                    required property int index
                    text: index < g.lives ? "❤️" : "🤍"
                    font.pixelSize: 28
                }
            }
        }

        Text {
            anchors { top: parent.top; topMargin: 40; horizontalCenter: parent.horizontalCenter }
            text: qsTr("Tocca i multipli in ordine, dal più piccolo al più grande")
            font.pixelSize: 18
            color: Theme.text
            opacity: 0.7
        }

        Flow {
            anchors { top: parent.top; topMargin: 90; left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors.margins: 20
            anchors.rightMargin: 140
            spacing: 18

            Repeater {
                model: g.multiples
                Rectangle {
                    id: fish
                    required property int modelData
                    width: 96; height: 96; radius: 48
                    color: Theme.dirRight
                    scale: fma.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    function shakeMe() { shakeAnim.start() }
                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: fish; property: "rotation"; to: -12; duration: 60 }
                        NumberAnimation { target: fish; property: "rotation"; to: 12; duration: 60 }
                        NumberAnimation { target: fish; property: "rotation"; to: 0; duration: 60 }
                    }

                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🐟"; font.pixelSize: 34 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: fish.modelData; font.pixelSize: 22; font.bold: true; color: "white" }
                    }

                    MouseArea { id: fma; anchors.fill: parent; onClicked: g.tapFish(fish) }
                }
            }
        }

        // la conchiglia: raccoglie i pesci pescati nell'ordine giusto
        Column {
            anchors { right: parent.right; bottom: parent.bottom; margins: 20 }
            spacing: 4
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🐚"; font.pixelSize: 74 }
            Rectangle {
                id: shell
                anchors.horizontalCenter: parent.horizontalCenter
                width: 70; height: 32; radius: 16
                color: Theme.panel
                border.color: Theme.boardLine
                border.width: 2
                Text { anchors.centerIn: parent; text: g.shellCount + "/10"; font.pixelSize: 15; font.bold: true; color: Theme.text }
            }
        }

        // strato dove "volano" i pesci pescati verso la conchiglia
        Item { id: flightLayer; anchors.fill: parent; z: 50 }
    }

    // ---------- schermata di scelta della tabellina ----------
    Rectangle {
        anchors.fill: parent
        color: Theme.background
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
