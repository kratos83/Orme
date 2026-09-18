// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Ortografia: trabocchetti comuni (a/ha, e/è, o/ho, anno/hanno, qu/cu,
// accenti). Una frase con uno spazio vuoto, tocca la parola scritta giusta.
MiniGame {
    id: g
    title: qsTr("Ortografia")
    age: qsTr("7-9 anni")
    levelCount: 10

    readonly property var pool: [
        { clue: qsTr("___ un cane simpatico"), a: qsTr("a"), b: qsTr("ha"), correct: qsTr("ha") },
        { clue: qsTr("Vado ___ scuola a piedi"), a: qsTr("a"), b: qsTr("ha"), correct: qsTr("a") },
        { clue: qsTr("Lui ___ molto stanco"), a: qsTr("e"), b: qsTr("è"), correct: qsTr("è") },
        { clue: qsTr("Io ___ Luca giochiamo insieme"), a: qsTr("e"), b: qsTr("è"), correct: qsTr("e") },
        { clue: qsTr("___ fame, mangio la mela"), a: qsTr("o"), b: qsTr("ho"), correct: qsTr("ho") },
        { clue: qsTr("Vuoi la pasta ___ il riso?"), a: qsTr("o"), b: qsTr("ho"), correct: qsTr("o") },
        { clue: qsTr("Loro ___ due gatti"), a: qsTr("anno"), b: qsTr("hanno"), correct: qsTr("hanno") },
        { clue: qsTr("L'___ scolastico inizia a settembre"), a: qsTr("anno"), b: qsTr("hanno"), correct: qsTr("anno") },
        { clue: qsTr("Batte nel petto: è il ___"), a: qsTr("quore"), b: qsTr("cuore"), correct: qsTr("cuore") },
        { clue: qsTr("Ci scrivo i compiti: il ___"), a: qsTr("cuaderno"), b: qsTr("quaderno"), correct: qsTr("quaderno") },
        { clue: qsTr("Ho sete, bevo l'___"), a: qsTr("acqua"), b: qsTr("aqua"), correct: qsTr("acqua") },
        { clue: qsTr("Prepara i piatti in cucina: il ___"), a: qsTr("cuoco"), b: qsTr("quoco"), correct: qsTr("cuoco") },
        { clue: qsTr("Ha quattro lati uguali: il ___"), a: qsTr("cuadrato"), b: qsTr("quadrato"), correct: qsTr("quadrato") },
        { clue: qsTr("Se piove esco con l'___"), a: qsTr("ombrello"), b: qsTr("onbrello"), correct: qsTr("ombrello") },
        { clue: qsTr("Suona le ___ in banda"), a: qsTr("tronba"), b: qsTr("tromba"), correct: qsTr("tromba") },
        { clue: qsTr("In vacanza andiamo in ___"), a: qsTr("montania"), b: qsTr("montagna"), correct: qsTr("montagna") },
        { clue: qsTr("Al circo salta la ___"), a: qsTr("shimmia"), b: qsTr("scimmia"), correct: qsTr("scimmia") }
    ]

    property var current: pool[0]
    property var options: []
    property bool answered: false
    property string filledWord: ""   // parola toccata, va al posto della lineetta

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        filledWord = ""
        current = pool[Math.floor(Math.random() * pool.length)]
        options = Math.random() < 0.5 ? [current.a, current.b] : [current.b, current.a]
    }

    // la frase con "___" sostituito dalla parola toccata (o dalla lineetta
    // sottolineata in rosso, finché non si è ancora toccato nulla)
    function clueHtml() {
        var parts = current.clue.split("___")
        var blank = filledWord !== ""
            ? "<b>" + filledWord + "</b>"
            : "<u><font color=\"#EF5350\">______</font></u>"
        return parts[0] + blank + (parts.length > 1 ? parts[1] : "")
    }

    Timer { id: clearBlank; interval: 700; onTriggered: g.filledWord = "" }

    function pick(word) {
        if (answered) return
        filledWord = word
        if (word === current.correct) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
            clearBlank.restart()
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Column {
            anchors.centerIn: parent
            spacing: 40
            width: Math.min(parent.width - 40, 560)

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                text: g.clueHtml()
                font.pixelSize: 28
                font.bold: true
                color: Theme.text
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24
                Repeater {
                    model: g.options
                    Rectangle {
                        id: opt
                        required property string modelData
                        width: 220; height: 90; radius: 20
                        color: Theme.dirLeft
                        opacity: g.answered && opt.modelData !== g.current.correct ? 0.4 : 1
                        scale: optMa.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text { anchors.centerIn: parent; text: opt.modelData; font.pixelSize: 30; font.bold: true; color: "white" }
                        MouseArea { id: optMa; anchors.fill: parent; enabled: !g.won; onClicked: g.pick(opt.modelData) }
                    }
                }
            }
        }
    }
}
