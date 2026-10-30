import QtQuick
import Orme

// "Il ritmo" - il concetto di SEQUENZA CHE SI RIPETE (pattern, riconoscimento).
// In alto una fila che segue un ritmo di colori e finisce con "?".
// In basso tre palline: il bambino tocca quella che continua il ritmo.
GameScaffold {
    id: scaffold
    title: qsTr("Il ritmo")
    age: qsTr("3-5 anni")
    showNext: won

    onRestartRequested: load(levelIndex)
    onNextRequested: goNext()
    onWinFinished: goNext()

    // ogni "ritmo" e' un blocchetto di indici colore che si ripete
    readonly property var patterns: [
        [0, 1],
        [1, 0],
        [0, 0, 1],
        [0, 1, 1],
        [0, 1, 2],
        [2, 1, 0],
        [0, 1, 0, 2],
        [0, 0, 1, 1],
        [0, 1, 2, 2],
        [0, 1, 1, 2]
    ]

    property int  levelIndex: 0
    property var  unit: [0, 1]
    property int  visibleLen: 4
    property int  answerIdx: 0
    property var  options: [0, 1, 2]
    property bool answered: false
    property bool won: false
    property int  mistakes: 0

    SoundBank { id: snd }

    function nextMsg() {
        return qsTr("Sei al livello ") + (((levelIndex + 1) % patterns.length) + 1)
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
        levelIndex = ((i % patterns.length) + patterns.length) % patterns.length
        unit = patterns[levelIndex]
        visibleLen = Math.min(unit.length * 2, 7)
        answerIdx = unit[visibleLen % unit.length]

        var opts = [answerIdx]
        var candidates = shuffle([0, 1, 2, 3, 4, 5])
        for (var k = 0; k < candidates.length && opts.length < 3; k++)
            if (opts.indexOf(candidates[k]) === -1)
                opts.push(candidates[k])
        options = shuffle(opts)

        answered = false
        won = false
        mistakes = 0
    }

    function solve() {
        answered = true
        won = true
        snd.win()
        scaffold.reward(3 - Math.min(2, mistakes), nextMsg())
    }

    Component.onCompleted: load(0)

    component Dot: Rectangle {
        property int colorIndex: 0
        radius: width / 2
        color: Theme.playColors[colorIndex]
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        // ===== la fila del ritmo =====
        Row {
            id: strip
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.16
            spacing: 12

            readonly property real cell:
                Math.max(40, Math.min(96, (scaffold.width - 60) / (scaffold.visibleLen + 1) - 12))

            Repeater {
                model: scaffold.visibleLen + 1

                Item {
                    width: strip.cell
                    height: strip.cell

                    // celle gia' note
                    Dot {
                        anchors.fill: parent
                        visible: index < scaffold.visibleLen
                        colorIndex: scaffold.unit[index % scaffold.unit.length]
                    }

                    // ultima cella: il "?" da indovinare
                    Rectangle {
                        anchors.fill: parent
                        visible: index === scaffold.visibleLen
                        radius: width / 2
                        color: scaffold.answered ? Theme.playColors[scaffold.answerIdx] : Theme.panel
                        border.color: Theme.boardLine
                        border.width: scaffold.answered ? 0 : 4

                        Text {
                            anchors.centerIn: parent
                            visible: !scaffold.answered
                            text: "❓"
                            font.pixelSize: parent.width * 0.55
                        }
                    }
                }
            }

            // piccolo rimbalzo di festa quando si risolve
            SequentialAnimation on scale {
                running: scaffold.answered
                NumberAnimation { from: 1.0; to: 1.08; duration: 160 }
                NumberAnimation { from: 1.08; to: 1.0; duration: 160 }
            }
        }

        // ===== le tre scelte =====
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.55
            spacing: 34

            Repeater {
                model: scaffold.options

                Rectangle {
                    id: opt
                    width: 128; height: 128
                    radius: 28
                    color: Theme.panel
                    border.color: Theme.boardLine
                    border.width: 3
                    opacity: scaffold.answered ? 0.4 : 1

                    Dot {
                        anchors.centerIn: parent
                        width: parent.width * 0.66
                        height: width
                        colorIndex: modelData
                    }

                    scale: optma.pressed && !scaffold.answered ? 0.93 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: opt; property: "rotation"; to: -12; duration: 55 }
                        NumberAnimation { target: opt; property: "rotation"; to:  12; duration: 55 }
                        NumberAnimation { target: opt; property: "rotation"; to:   0; duration: 55 }
                    }

                    MouseArea {
                        id: optma
                        anchors.fill: parent
                        enabled: !scaffold.answered
                        onClicked: {
                            if (modelData === scaffold.answerIdx) {
                                scaffold.solve()
                            } else {
                                scaffold.mistakes += 1
                                snd.nope()
                                shake.restart()
                            }
                        }
                    }
                }
            }
        }
    }
}
