// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Il treno dei numeri" - a ogni stazione gli animali scendono dai vagoni e si
// mettono in fila sulla banchina, cinque per riga come le dita di una mano.
// Il bambino li conta (toccandoli compare il numero) e tocca la cifra giusta.
// Fra una stazione e l'altra ci sono semaforo, STOP e divieto di accesso (vedi
// RailGame). Le quantita' crescono di livello in livello, fino a 9; nell'ultimo
// c'e' anche lo zero: dal treno non scende nessuno.
RailGame {
    id: ng
    title: qsTr("Il treno dei numeri")
    age: qsTr("4-5 anni")
    wagonCount: 5
    trackRatio: 0.3
    wagonColors: [Theme.playColors[1], Theme.playColors[2], Theme.playColors[3],
                  Theme.playColors[4], Theme.playColors[5]]
    plates: ["", "", "", "", ""]
    taskIcon: allOut ? "question" : "walker"
    taskHint: !allOut ? qsTr("Gli animali scendono...")
            : solved ? qsTr("Bravo! Sono %1").arg(group.length)
            : qsTr("Quanti sono scesi?")

    readonly property var ranges: [[1, 3], [1, 4], [1, 5], [2, 7], [3, 9], [0, 9]]
    readonly property var animals: ["rabbit", "cat", "dog", "panda", "frog", "fox", "koala",
                                    "pig", "lion", "tiger", "monkey", "chick"]

    property var  groups: []       // per stazione: gli animali che scendono
    property var  group: []        // quelli di adesso
    property int  off: 0           // quanti sono gia' scesi
    property var  counted: []      // quelli toccati, in ordine
    property var  choices: []      // le tre cifre fra cui scegliere
    property bool solved: false
    readonly property bool allOut: phase === "task" && off >= group.length && !waitDoor.running

    // i posti ai finestrini: si riempiono dal vagone vicino alla locomotiva
    function seatsFor(list, gone) {
        var s = []
        for (var w = 0; w < wagonCount; w++) s.push(["", ""])
        for (var j = gone; j < list.length; j++)
            s[wagonCount - 1 - Math.floor(j / 2)][1 - j % 2] = list[j]
        return s
    }

    function board(k) {
        group = groups[k]
        off = 0
        counted = []
        solved = false
        seats = seatsFor(group, 0)
    }

    onLevelStarted: (i) => {
        waitDoor.stop()
        stepOut.stop()
        nextTimer.stop()
        var lo = ranges[i % ranges.length][0], hi = ranges[i % ranges.length][1]
        var all = []
        for (var n = lo; n <= hi; n++) all.push(n)
        var picked = shuffle(all).slice(0, stations)
        // se c'e' lo zero nel livello, capita una volta (non alla prima stazione)
        if (lo === 0 && picked.indexOf(0) < 0) picked[1 + Math.floor(Math.random() * 2)] = 0
        if (picked[0] === 0) { picked[0] = picked[1]; picked[1] = 0 }
        groups = picked.map((c) => shuffle(animals).slice(0, c))
        board(0)
    }

    onDeparting: (k) => board(k)

    onStationArrived: (s) => {
        var n = group.length
        var lo = ranges[levelIndex % ranges.length][0]
        var hi = Math.max(ranges[levelIndex % ranges.length][1], lo + 2)
        // due cifre sbagliate vicine a quella giusta
        var near = []
        for (var c = lo; c <= hi; c++) if (c !== n) near.push(c)
        near = shuffle(near).sort((a, b) => Math.abs(a - n) - Math.abs(b - n))
        choices = [n, near[0], near[1]].sort((a, b) => a - b)
        waitDoor.restart()
    }

    // si aprono le porte, poi scendono uno alla volta
    Timer { id: waitDoor; interval: 700; onTriggered: stepOut.restart() }
    Timer {
        id: stepOut
        interval: 420
        repeat: true
        running: false
        onTriggered: {
            if (ng.off >= ng.group.length) { stop(); return }
            ng.off += 1
            ng.seats = ng.seatsFor(ng.group, ng.off)
            ng.sound.tap()
        }
    }

    // contare toccando: ogni animale prende il numero successivo
    function count(j) {
        if (!allOut || solved || counted.indexOf(j) >= 0) return
        counted = counted.concat([j])
        sound.tap()
    }

    function answer(n) {
        if (!allOut || solved) return
        if (n !== group.length) {
            mistake()
            counted = []
            return
        }
        solved = true
        counted = group.map((a, j) => j)
        sound.ok()
        nextTimer.restart()
    }

    Timer { id: nextTimer; interval: 2000; onTriggered: ng.taskDone() }

    // ---------- la banchina ----------
    Item {
        id: stage
        anchors.fill: parent

        readonly property real platform: ng.groundY + 22
        // due file di animali e sotto i pulsanti con le cifre
        readonly property real pic: Math.max(34, Math.min(84, (height - platform - 112) / 2.15, width / 8))
        readonly property real buttonsY: Math.min(height - 104, platform + pic * 2.15 + 10)

        Repeater {
            model: ng.group.length

            Item {
                id: friend
                required property int index
                objectName: "friend" + index
                readonly property bool out: ng.phase === "task" && index < ng.off
                // il finestrino da cui scende
                readonly property int wagon: ng.wagonCount - 1 - Math.floor(index / 2)
                readonly property real seatX: ng.wagonX(wagon) + (index % 2 ? -0.23 : 0.23) * ng.cw
                readonly property real seatY: ng.trackY + ng.ch * 0.38
                // il posto sulla banchina
                readonly property int row: Math.floor(index / 5)
                readonly property int inRow: Math.min(5, ng.group.length - row * 5)
                readonly property real spotX: stage.width / 2 + (index % 5 - (inRow - 1) / 2) * stage.pic * 1.3
                readonly property real spotY: stage.platform + stage.pic / 2 + row * stage.pic * 1.12
                readonly property int number: ng.counted.indexOf(index) + 1

                width: stage.pic; height: stage.pic
                x: (out ? spotX : seatX) - width / 2
                y: (out ? spotY : seatY) - height / 2
                visible: out
                scale: out ? 1 : 0.4
                Behavior on x { enabled: ng.phase === "task"; NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
                Behavior on y { enabled: ng.phase === "task"; NumberAnimation { duration: 450; easing.type: Easing.InQuad } }
                Behavior on scale { enabled: ng.phase === "task"; NumberAnimation { duration: 450 } }

                AppIcon {
                    id: face
                    name: ng.group[friend.index] || "rabbit"
                    size: friend.width
                    SequentialAnimation on y {   // saltano di gioia
                        running: ng.solved
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) face.y = 0
                        PauseAnimation { duration: friend.index * 70 }
                        NumberAnimation { to: -12; duration: 160; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 0; duration: 160; easing.type: Easing.InQuad }
                        PauseAnimation { duration: 200 }
                    }
                }
                Rectangle {   // il numero della conta
                    visible: friend.number > 0
                    width: Math.max(22, friend.width * 0.42); height: width; radius: width / 2
                    x: friend.width - width * 0.8; y: -height * 0.2
                    color: "#1E88E5"
                    border.color: "white"; border.width: 2
                    Text {
                        anchors.centerIn: parent
                        text: friend.number
                        color: "white"; font.bold: true
                        font.pixelSize: Math.max(1, parent.height * 0.66)
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: ng.count(friend.index) }
            }
        }

        // nessuno scende
        Text {
            visible: ng.allOut && ng.group.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: stage.platform + stage.pic * 0.6
            text: qsTr("Il treno è vuoto...")
            color: "white"; style: Text.Outline; styleColor: "#2E7D32"
            font.pixelSize: 32; font.bold: true
        }

        Row {
            visible: ng.allOut
            anchors.horizontalCenter: parent.horizontalCenter
            y: stage.buttonsY
            spacing: 28
            Repeater {
                model: ng.choices
                Rectangle {
                    id: digit
                    required property int modelData
                    objectName: "digit" + modelData
                    readonly property bool chosen: ng.solved && modelData === ng.group.length
                    width: 100; height: 88; radius: 24
                    color: chosen ? Theme.accent : "white"
                    border.color: chosen ? "white" : "#FFB300"; border.width: 5
                    opacity: ng.solved && !chosen ? 0.35 : 1
                    scale: chosen ? 1.15 : (digitArea.pressed ? 0.93 : 1)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                    Candy {}
                    Text {
                        anchors.centerIn: parent
                        text: digit.modelData
                        color: digit.chosen ? "white" : Theme.title
                        font.pixelSize: 56; font.bold: true
                    }
                    MouseArea { id: digitArea; anchors.fill: parent; onClicked: ng.answer(digit.modelData) }
                }
            }
        }
    }
}
