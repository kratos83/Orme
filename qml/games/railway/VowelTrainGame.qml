// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Il treno delle vocali" - cinque vagoni con le vocali A E I O U. A ogni
// stazione aspetta qualcuno: si trascina (o si tocca il vagone) sul vagone
// della vocale con cui comincia la sua parola. Fra una stazione e l'altra ci
// sono semaforo, STOP e divieto di accesso (vedi RailGame).
// Livelli: prima la parola e' intera, poi manca l'iniziale; negli ultimi due
// anche i vagoni cambiano posto. Nei livelli pari salgono in due per stazione.
RailGame {
    id: vg
    title: qsTr("Il treno delle vocali")
    age: qsTr("4-5 anni")
    wagonCount: 5
    taskIcon: "point-up"
    taskHint: busy || !current ? qsTr("Evviva!") : qsTr("In quale vagone sale?")

    readonly property var vowels: ["A", "E", "I", "O", "U"]
    readonly property var vowelColor: ({ A: Theme.playColors[1], E: Theme.playColors[2],
                                         I: Theme.playColors[3], O: Theme.playColors[4],
                                         U: Theme.playColors[5] })
    // parola -> figura (assets/icons/)
    readonly property var words: ({
        A: [["APE", "bee"], ["AEREO", "airplane"], ["ANANAS", "pineapple"], ["ALBERO", "tree"]],
        E: [["ELEFANTE", "elephant"], ["ELICOTTERO", "helicopter"]],
        I: [["ISOLA", "island"], ["IPPOPOTAMO", "hippo"], ["INSALATA", "salad"]],
        O: [["ORSO", "bear"], ["OMBRELLO", "umbrella"], ["OCA", "goose"], ["OCCHI", "eyes"]],
        U: [["UVA", "grapes"], ["UOVO", "egg"], ["UNICORNO", "unicorn"], ["UCCELLO", "bird"]]
    })

    property int  perStation: 1
    property bool hidden: false       // manca l'iniziale
    property var  order: vowels       // le vocali dei vagoni, da sinistra
    property var  queue: []           // chi sale in questo livello, in ordine
    property int  turn: 0             // il prossimo di queue
    property int  lastOfStation: 0
    property bool busy: false         // qualcuno sta salendo
    readonly property var current: turn < queue.length ? queue[turn] : null
    readonly property bool asking: phase === "task" && current !== null && turn < lastOfStation

    onLevelStarted: (i) => {
        boardAnim.stop()
        nextTimer.stop()
        busy = false
        var lv = i % levelCount
        perStation = lv % 2 === 0 ? 1 : 2
        hidden = lv >= 2
        order = lv >= 4 ? shuffle(vowels) : vowels

        // le vocali girano a giri completi: nessuna esce piu' di due volte
        var letters = shuffle(vowels).concat(shuffle(vowels)).slice(0, stations * perStation)
        var left = {}
        vowels.forEach((v) => left[v] = shuffle(words[v]))
        queue = letters.map((v) => { var w = left[v].pop(); return { word: w[0], icon: w[1], vowel: v } })
        turn = 0
        lastOfStation = 0
        plates = order
        wagonColors = order.map((v) => vowelColor[v])
        seats = order.map(() => ["", ""])
        card.filled = false
    }

    onStationArrived: (s) => {
        lastOfStation = (s + 1) * perStation
        card.filled = false
        card.goHome()
    }

    onWagonTapped: (n) => put(n)

    // il passeggero di adesso va nel vagone n
    function put(n) {
        if (!asking || busy || n < 0) return
        if (order[n] !== current.vowel) {
            mistake()
            shake(n)
            card.goHome()
            return
        }
        busy = true
        card.filled = true
        sound.ok()
        boardAnim.wagon = n
        boardAnim.restart()
    }

    function seated(n) {
        var s = seats.map((p) => p.slice())
        s[n][s[n][0] === "" ? 0 : 1] = current.icon
        seats = s
        nextTimer.restart()
    }

    Timer {   // il tempo di leggere la parola completa
        id: nextTimer
        interval: 1300
        onTriggered: {
            vg.turn += 1
            vg.busy = false
            if (vg.turn >= vg.lastOfStation) vg.taskDone()
            else { card.filled = false; card.goHome() }
        }
    }

    // ---------- il passeggero sulla banchina ----------
    Item {
        id: stage
        anchors.fill: parent

        Item {
            id: card
            objectName: "passenger"
            property bool filled: false
            readonly property real pic: Math.max(56, Math.min(130, stage.height - vg.groundY - 116))
            readonly property real homeX: (stage.width - width) / 2
            readonly property real homeY: vg.groundY + 22

            function goHome() { x = homeX; y = homeY; face.scale = 1 }
            onHomeXChanged: if (!grip.drag.active && !vg.busy) goHome()
            onHomeYChanged: if (!grip.drag.active && !vg.busy) goHome()

            visible: vg.asking
            width: pic * 1.2; height: pic

            AppIcon {
                id: face
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !(vg.busy && !boardAnim.running)   // ormai e' al finestrino
                name: vg.current ? vg.current.icon : "bee"
                size: card.pic
            }

            MouseArea {
                id: grip
                anchors.fill: parent
                enabled: vg.asking && !vg.busy
                drag.target: card
                drag.threshold: 4
                drag.minimumX: 0
                drag.maximumX: stage.width - card.width
                drag.minimumY: 0
                drag.maximumY: stage.height - card.height
                onPressed: vg.sound.tap()
                onReleased: {
                    var n = vg.wagonAt(card.x + card.width / 2, card.y + card.height / 2)
                    if (n < 0) card.goHome()
                    else vg.put(n)
                }
            }

            // salta al finestrino del suo vagone
            ParallelAnimation {
                id: boardAnim
                property int wagon: 0
                NumberAnimation { target: card; property: "x"; to: vg.wagonX(boardAnim.wagon) - card.width / 2; duration: 520; easing.type: Easing.InOutQuad }
                NumberAnimation { target: card; property: "y"; to: vg.trackY + vg.ch * 0.38 - card.height / 2; duration: 520; easing.type: Easing.OutBack }
                NumberAnimation { target: face; property: "scale"; to: vg.cw * 0.23 / card.pic; duration: 520 }
                onFinished: vg.seated(wagon)
            }
        }

        // la parola, con l'iniziale da scoprire
        Rectangle {
            objectName: "word"
            visible: vg.asking
            anchors.horizontalCenter: parent.horizontalCenter
            y: card.homeY + card.pic + 6
            width: letters.implicitWidth + 36
            height: 60; radius: 30
            color: "white"
            border.color: "#FFD54F"; border.width: 3
            Row {
                id: letters
                anchors.centerIn: parent
                spacing: 4
                Rectangle {
                    readonly property bool blank: vg.hidden && !card.filled
                    width: 40; height: 46; radius: 10
                    color: blank ? "#FFF3E0" : (vg.current ? vg.vowelColor[vg.current.vowel] : "white")
                    border.color: blank ? "#FB8C00" : "transparent"; border.width: 3
                    Text {
                        anchors.centerIn: parent
                        text: parent.blank ? "?" : (vg.current ? vg.current.vowel : "")
                        color: parent.blank ? "#FB8C00" : "white"
                        style: parent.blank ? Text.Normal : Text.Outline
                        styleColor: "#5D4037"
                        font.pixelSize: 34; font.bold: true
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: vg.current ? vg.current.word.slice(1) : ""
                    color: Theme.text
                    font.pixelSize: 34; font.bold: true
                }
            }
        }
    }
}
