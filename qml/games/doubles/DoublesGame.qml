// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Doppie: una frase con uno spazio vuoto e due parole quasi uguali (una con
// la doppia, una senza): tocca quella giusta.
MiniGame {
    id: g
    title: qsTr("Le doppie")
    age: qsTr("7-8 anni")
    levelCount: 10

    readonly property var pool: [
        { clue: qsTr("Per giocare a calcio uso la ___"), a: qsTr("pala"), b: qsTr("palla"), correct: qsTr("palla") },
        { clue: qsTr("Dopo aver corso ho tanta ___"), a: qsTr("sete"), b: qsTr("sette"), correct: qsTr("sete") },
        { clue: qsTr("Il numero dopo il sei è il ___"), a: qsTr("sete"), b: qsTr("sette"), correct: qsTr("sette") },
        { clue: qsTr("Il trattore tira il ___"), a: qsTr("caro"), b: qsTr("carro"), correct: qsTr("carro") },
        { clue: qsTr("Il papà di mio papà è mio ___"), a: qsTr("nono"), b: qsTr("nonno"), correct: qsTr("nonno") },
        { clue: qsTr("Vengo dopo l'ottavo: sono il ___"), a: qsTr("nono"), b: qsTr("nonno"), correct: qsTr("nono") },
        { clue: qsTr("Ho tanto ___, vado a dormire"), a: qsTr("sono"), b: qsTr("sonno"), correct: qsTr("sonno") },
        { clue: qsTr("Abito in una ___ con giardino"), a: qsTr("casa"), b: qsTr("cassa"), correct: qsTr("casa") },
        { clue: qsTr("Metto la frutta nella ___ di legno"), a: qsTr("casa"), b: qsTr("cassa"), correct: qsTr("cassa") },
        { clue: qsTr("Di giorno c'è il sole, di ___ c'è la luna"), a: qsTr("note"), b: qsTr("notte"), correct: qsTr("notte") },
        { clue: qsTr("Il pentagramma ha le ___ musicali"), a: qsTr("note"), b: qsTr("notte"), correct: qsTr("note") },
        { clue: qsTr("Il bambino piccolo mangia la ___"), a: qsTr("papa"), b: qsTr("pappa"), correct: qsTr("pappa") },
        { clue: qsTr("Due persone insieme formano una ___"), a: qsTr("copia"), b: qsTr("coppia"), correct: qsTr("coppia") },
        { clue: qsTr("Fai una ___ del disegno"), a: qsTr("copia"), b: qsTr("coppia"), correct: qsTr("copia") },
        { clue: qsTr("Indosso la ___ per fare sport"), a: qsTr("tuta"), b: qsTr("tutta"), correct: qsTr("tuta") },
        { clue: qsTr("Ho mangiato ___ la torta"), a: qsTr("tuta"), b: qsTr("tutta"), correct: qsTr("tutta") },
        { clue: qsTr("Frutta e verdura mi fanno stare ___"), a: qsTr("sano"), b: qsTr("sanno"), correct: qsTr("sano") },
        { clue: qsTr("Sulla testa metto il ___"), a: qsTr("capello"), b: qsTr("cappello"), correct: qsTr("cappello") },
        { clue: qsTr("Scrivo con la ___"), a: qsTr("pena"), b: qsTr("penna"), correct: qsTr("penna") },
        { clue: qsTr("Le piante crescono nella ___"), a: qsTr("sera"), b: qsTr("serra"), correct: qsTr("serra") }
    ]

    property var current: pool[0]
    property var options: []   // [a, b] in ordine casuale
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
                        color: Theme.dirUp
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
