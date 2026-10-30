import QtQuick
import Orme

// "Cuciniamo insieme" - gioco di ruolo in cucina, il concetto di SEQUENZA
// di passi (un piccolo algoritmo). In alto le figure mescolate, in basso le
// caselle 1-2(-3): tocca le figure nell'ordine giusto per completare
// l'azione (preparare la pappa, lavare i piatti...).
GameScaffold {
    id: scaffold
    title: qsTr("Cuciniamo insieme")
    age: qsTr("3-4 anni")
    showNext: won

    onRestartRequested: load(levelIndex)
    onNextRequested: goNext()
    onWinFinished: goNext()

    readonly property var sequences: [
        ["🥣", "🥛"],
        ["🫖", "☕"],
        ["🥚", "🍳"],
        ["🍞", "🧈"],
        ["🛒", "🏠"],
        ["🧺", "👕"],
        ["🍽️", "🧽", "✨"],
        ["🍎", "🔪", "🍽️"]
    ]

    property int  levelIndex: 0
    property var  correct: sequences[0]
    property var  shuffled: sequences[0]
    property var  placed: []
    property bool won: false
    property int  mistakes: 0

    SoundBank { id: snd }

    function nextMsg() {
        return qsTr("Sei al livello ") + (((levelIndex + 1) % sequences.length) + 1)
    }
    function goNext() {
        if (!won) return
        load(levelIndex + 1)
    }

    function shuffle(a) {
        var r = a.slice()
        for (var i = r.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1))
            var t = r[i]; r[i] = r[j]; r[j] = t
        }
        return r
    }

    function load(i) {
        levelIndex = ((i % sequences.length) + sequences.length) % sequences.length
        correct = sequences[levelIndex].slice()
        var s = shuffle(correct)
        var tries = 0
        while (s.join() === correct.join() && tries < 10) { s = shuffle(correct); tries++ }
        shuffled = s
        placed = []
        won = false
        mistakes = 0
    }

    function used(e) { return placed.indexOf(e) !== -1 }

    function place(e) {
        placed = placed.concat([e])
        if (placed.length === correct.length) {
            won = true
            snd.win()
            scaffold.reward(3 - Math.min(2, mistakes), nextMsg())
        } else {
            snd.ok()
        }
    }

    Component.onCompleted: load(0)

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        // ===== oggetti mescolati =====
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.20
            spacing: 26

            Repeater {
                model: scaffold.shuffled

                Rectangle {
                    id: pick
                    width: 150; height: 150
                    radius: 26
                    color: Theme.panel
                    border.color: Theme.boardLine
                    border.width: 3
                    opacity: scaffold.used(modelData) ? 0.18 : 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 90
                        visible: !scaffold.used(modelData)
                    }

                    scale: pickma.pressed && !scaffold.used(modelData) ? 0.93 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: pick; property: "rotation"; to: -12; duration: 55 }
                        NumberAnimation { target: pick; property: "rotation"; to:  12; duration: 55 }
                        NumberAnimation { target: pick; property: "rotation"; to:   0; duration: 55 }
                    }

                    MouseArea {
                        id: pickma
                        anchors.fill: parent
                        enabled: !scaffold.won && !scaffold.used(modelData)
                        onClicked: {
                            if (modelData === scaffold.correct[scaffold.placed.length])
                                scaffold.place(modelData)
                            else {
                                scaffold.mistakes += 1
                                snd.nope()
                                shake.restart()
                            }
                        }
                    }
                }
            }
        }

        // freccia "in ordine"
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.48
            text: "▼"
            font.pixelSize: 40
            color: Theme.text
            opacity: 0.5
        }

        // ===== caselle in ordine =====
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.60
            spacing: 26

            Repeater {
                model: scaffold.correct.length

                Rectangle {
                    width: 160; height: 160
                    radius: 26
                    color: Theme.boardFill
                    border.color: Theme.boardLine
                    border.width: 4

                    Text {   // numero della casella, finche' e' vuota
                        anchors.centerIn: parent
                        visible: index >= scaffold.placed.length
                        text: index + 1
                        font.pixelSize: 60
                        font.bold: true
                        color: Theme.boardLine
                    }

                    Text {   // oggetto messo qui
                        anchors.centerIn: parent
                        visible: index < scaffold.placed.length
                        text: index < scaffold.placed.length ? scaffold.placed[index] : ""
                        font.pixelSize: 96

                        SequentialAnimation on scale {
                            running: index < scaffold.placed.length
                            NumberAnimation { from: 0.2; to: 1.15; duration: 160; easing.type: Easing.OutBack }
                            NumberAnimation { from: 1.15; to: 1.0; duration: 120 }
                        }
                    }
                }
            }
        }
    }
}
