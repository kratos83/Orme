// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Pronomi: si sceglie il tipo (personali, possessivi, dimostrativi,
// indefiniti, relativi), poi si completa la frase toccando il pronome giusto.
MiniGame {
    id: g
    title: qsTr("Pronomi")
    age: qsTr("9-10 anni")
    levelCount: 8

    readonly property var categories: [
        { key: "personali", label: qsTr("Personali") },
        { key: "possessivi", label: qsTr("Possessivi") },
        { key: "dimostrativi", label: qsTr("Dimostrativi") },
        { key: "indefiniti", label: qsTr("Indefiniti") },
        { key: "relativi", label: qsTr("Relativi") }
    ]

    readonly property var data: ({
        personali: [
            { clue: qsTr("___ sei proprio simpatico."), correct: qsTr("Tu"), wrong: qsTr("Te") },
            { clue: qsTr("Ho visto Sara e ___ ho chiesto di giocare con me."), correct: qsTr("le"), wrong: qsTr("gli") },
            { clue: qsTr("___ andiamo tutti insieme al mare."), correct: qsTr("Noi"), wrong: qsTr("Ci") },
            { clue: qsTr("Marco ___ ha regalato un libro."), correct: qsTr("mi"), wrong: qsTr("io") }
        ],
        possessivi: [
            { clue: qsTr("La mia cartella è più vecchia della ___."), correct: qsTr("tua"), wrong: qsTr("sue") },
            { clue: qsTr("Questo cane non è ___, è di Luca."), correct: qsTr("mio"), wrong: qsTr("mia") },
            { clue: qsTr("I ___ compiti sono già finiti."), correct: qsTr("tuoi"), wrong: qsTr("tua") },
            { clue: qsTr("Quella casa è ___, l'hanno costruita loro."), correct: qsTr("loro"), wrong: qsTr("suoi") }
        ],
        dimostrativi: [
            { clue: qsTr("Questi occhiali sono da sole, ___ da vista."), correct: qsTr("quelli"), wrong: qsTr("quegli") },
            { clue: qsTr("___ zaino è più pesante di quello."), correct: qsTr("Questo"), wrong: qsTr("Questi") },
            { clue: qsTr("Preferisco ___ maglietta a quella rossa."), correct: qsTr("questa"), wrong: qsTr("queste") },
            { clue: qsTr("Non capisco ___ che stai dicendo."), correct: qsTr("ciò"), wrong: qsTr("quello") }
        ],
        indefiniti: [
            { clue: qsTr("Hai raccolto alcuni fiori? Ne ho raccolti ___."), correct: qsTr("molti"), wrong: qsTr("qualcuni") },
            { clue: qsTr("___ ha bussato alla porta."), correct: qsTr("Qualcuno"), wrong: qsTr("Ognuno") },
            { clue: qsTr("___ gli alunni hanno fatto i compiti."), correct: qsTr("Tutti"), wrong: qsTr("Nessuno") },
            { clue: qsTr("Non c'è ___ di nuovo oggi."), correct: qsTr("niente"), wrong: qsTr("molti") }
        ],
        relativi: [
            { clue: qsTr("Ho visto il film ___ mi hai parlato."), correct: qsTr("di cui"), wrong: qsTr("per cui") },
            { clue: qsTr("La ragazza ___ hai incontrato è mia cugina."), correct: qsTr("che"), wrong: qsTr("chi") },
            { clue: qsTr("Questo è il motivo ___ sono in ritardo."), correct: qsTr("per cui"), wrong: qsTr("di cui") },
            { clue: qsTr("___ dorme non piglia pesci."), correct: qsTr("Chi"), wrong: qsTr("Che") }
        ]
    })

    property string category: "personali"
    property bool started: false
    property var current: data.personali[0]
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
        var pool = data[category]
        current = pool[Math.floor(Math.random() * pool.length)]
        options = Math.random() < 0.5 ? [current.correct, current.wrong] : [current.wrong, current.correct]
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
        if (answered || !started) return
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
        visible: g.started

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
                        color: Theme.accent
                        opacity: g.answered && opt.modelData !== g.current.correct ? 0.4 : 1
                        scale: optMa.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text { anchors.centerIn: parent; text: opt.modelData; font.pixelSize: 26; font.bold: true; color: "white" }
                        MouseArea { id: optMa; anchors.fill: parent; enabled: !g.won; onClicked: g.pick(opt.modelData) }
                    }
                }
            }
        }
    }

    // ---------- schermata di scelta del tipo di pronome ----------
    Rectangle {
        anchors.fill: parent
        color: Theme.background
        visible: !g.started

        Column {
            anchors.centerIn: parent
            spacing: 30

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Scegli il tipo di pronome")
                font.pixelSize: 28
                font.bold: true
                color: Theme.text
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Repeater {
                    model: g.categories
                    Rectangle {
                        id: catChip
                        required property var modelData
                        width: 260; height: 64; radius: 20
                        color: g.category === modelData.key ? Theme.accent : Theme.panel
                        border.color: Theme.boardLine
                        border.width: 3
                        scale: catMa.pressed ? 0.96 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text {
                            anchors.centerIn: parent
                            text: catChip.modelData.label
                            font.pixelSize: 22
                            font.bold: true
                            color: g.category === catChip.modelData.key ? "white" : Theme.text
                        }
                        MouseArea { id: catMa; anchors.fill: parent; onClicked: g.category = catChip.modelData.key }
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200; height: 76; radius: 22
                color: Theme.dirUp
                scale: startMa.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }
                Text { anchors.centerIn: parent; text: qsTr("Inizia"); font.pixelSize: 26; font.bold: true; color: "white" }
                MouseArea { id: startMa; anchors.fill: parent; onClicked: { g.started = true; g.buildLevel(0) } }
            }
        }
    }
}
