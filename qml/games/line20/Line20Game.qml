// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "I numeri fino a 20" - per la classe prima, ispirato al metodo analogico di
// Camillo Bortolato: la quantita' si riconosce a colpo d'occhio sulla linea
// dei tasti (cinquine e decine, come le mani) e si alza con un solo gesto,
// senza contare uno per uno. Dalle quantita' si passa ai nomi dei numeri e
// alle cifre, poi agli amici del 10, alle addizioni e alle sottrazioni.
// Non e' il materiale ufficiale del metodo.
MiniGame {
    id: g
    title: qsTr("I numeri fino a 20")
    scenery: "scuola"
    age: qsTr("6-7 anni")
    levelCount: 8

    property string mode: ""   // "" = scelta, poi explore, read, raise, friends, add, sub

    // quello che mostra la linea
    property int litFrom: 1
    property int litTo: 0
    property int splitAt: 20
    property int ghostFrom: 21
    property int ghostTo: 0
    property int slotsTo: 0
    property bool covered: false
    property bool showDigits: false

    // la domanda
    property int numA: 0
    property int numB: 0
    property int answer: 0
    property int step: 0          // add/sub: 0 e 1 si muovono i tasti, 2 si risponde
    property string ask: ""       // raise: "digit", "word" o "ordinal"
    property bool flash: false
    property var choices: []
    property var wrongChoices: []
    property int previous: -1     // per non ripetere subito lo stesso numero

    readonly property var words: [
        qsTr("zero"), qsTr("uno"), qsTr("due"), qsTr("tre"), qsTr("quattro"),
        qsTr("cinque"), qsTr("sei"), qsTr("sette"), qsTr("otto"), qsTr("nove"),
        qsTr("dieci"), qsTr("undici"), qsTr("dodici"), qsTr("tredici"),
        qsTr("quattordici"), qsTr("quindici"), qsTr("sedici"), qsTr("diciassette"),
        qsTr("diciotto"), qsTr("diciannove"), qsTr("venti")
    ]

    readonly property var activities: [
        { m: "explore", label: qsTr("Gioca con i tasti"), icon: "hand",       color: "#26A69A" },
        { m: "read",    label: qsTr("Quanti sono?"),      icon: "eyes",       color: "#42A5F5" },
        { m: "raise",   label: qsTr("Alza i tasti"),      icon: "point-up",   color: "#AB47BC" },
        { m: "friends", label: qsTr("Amici del 10"),      icon: "heart-red",  color: "#FFA726" },
        { m: "add",     label: qsTr("Aggiungi"),          icon: "plus",       color: "#66BB6A" },
        { m: "sub",     label: qsTr("Togli"),             icon: "minus",      color: "#EF5350" }
    ]

    // ---------- livelli ----------
    readonly property var readLevels: [
        { lo: 1,  hi: 5,  anywhere: false, flash: false },
        { lo: 1,  hi: 5,  anywhere: false, flash: true },
        { lo: 4,  hi: 10, anywhere: false, flash: false },
        { lo: 4,  hi: 10, anywhere: false, flash: true },
        { lo: 2,  hi: 10, anywhere: true,  flash: false },
        { lo: 11, hi: 20, anywhere: false, flash: false },
        { lo: 8,  hi: 20, anywhere: false, flash: true },
        { lo: 3,  hi: 20, anywhere: true,  flash: true }
    ]
    readonly property var raiseLevels: [
        { lo: 1,  hi: 5,  ask: "digit" },
        { lo: 3,  hi: 10, ask: "digit" },
        { lo: 3,  hi: 10, ask: "word" },
        { lo: 1,  hi: 10, ask: "ordinal" },
        { lo: 6,  hi: 20, ask: "digit" },
        { lo: 6,  hi: 20, ask: "word" },
        { lo: 6,  hi: 20, ask: "ordinal" },
        { lo: 11, hi: 20, ask: "word" }
    ]
    readonly property var friendTotals: [5, 5, 10, 10, 10, 10, 20, 20]
    // intervallo del totale (addizione) o del primo numero (sottrazione);
    // "ten" = esercizi intorno alla decina (10 + n, n - n = 10)
    readonly property var sumLevels: [
        { lo: 2, hi: 5 }, { lo: 4, hi: 8 }, { lo: 6, hi: 10 }, { lo: 8, hi: 10 },
        { lo: 11, hi: 19, ten: true }, { lo: 11, hi: 15 }, { lo: 11, hi: 20 }, { lo: 14, hi: 20 }
    ]

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function randInt(min, max) { return min + Math.floor(Math.random() * (max - min + 1)) }

    function pick(min, max) {
        var n = randInt(min, max)
        if (n === previous && max > min) n = n === max ? min : n + 1
        previous = n
        return n
    }

    function makeChoices(correct, max) {
        var near = [correct - 1, correct + 1, correct - 5, correct + 5,
                    correct - 10, correct + 10, correct - 2, correct + 2]
        near.sort(() => Math.random() - 0.5)
        var list = [correct]
        for (var i = 0; i < near.length && list.length < 4; i++)
            if (near[i] >= 1 && near[i] <= max && list.indexOf(near[i]) < 0)
                list.push(near[i])
        for (var n = 1; list.length < 4; n++)
            if (list.indexOf(n) < 0) list.push(n)
        return list.sort((a, b) => a - b)
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        peekTimer.stop()
        covered = false
        flash = false
        litFrom = 1; litTo = 0
        splitAt = 20
        ghostFrom = 21; ghostTo = 0
        slotsTo = 0
        step = 0
        ask = ""
        choices = []
        wrongChoices = []

        if (mode === "read") {
            var r = readLevels[i]
            answer = pick(r.lo, r.hi)
            // dall'inizio, dalla fine o dal centro della linea
            var where = r.anywhere ? randInt(0, 2) : 0
            litFrom = where === 0 ? 1 : (where === 1 ? 21 - answer : 11 - Math.ceil(answer / 2))
            litTo = litFrom + answer - 1
            choices = makeChoices(answer, r.hi <= 5 ? 5 : (r.hi <= 10 ? 10 : 20))
            flash = r.flash
            if (flash) peekTimer.restart()
        } else if (mode === "raise") {
            var l = raiseLevels[i]
            ask = l.ask
            answer = pick(l.lo, l.hi)
        } else if (mode === "friends") {
            var total = friendTotals[i]
            numB = total
            numA = pick(total === 20 ? 11 : 1, total - 1)
            answer = total - numA
            litTo = numA
            slotsTo = total
            choices = makeChoices(answer, total === 5 ? 5 : 10)
        } else if (mode === "add") {
            var s = sumLevels[i]
            var sum = pick(s.lo, s.hi)
            numA = s.ten ? 10 : randInt(1, sum - 1)
            numB = sum - numA
            answer = sum
        } else if (mode === "sub") {
            var t = sumLevels[i]
            numA = pick(t.lo, t.hi)
            numB = t.ten ? numA - 10 : randInt(1, numA - 1)
            answer = numA - numB
            litTo = numA
        }
    }

    function choose(m) {
        mode = m
        previous = -1
        load(0)
    }

    function peek() {
        covered = false
        peekTimer.restart()
    }

    Timer {
        id: peekTimer
        interval: 2200
        onTriggered: if (g.flash && !g.won) g.covered = true
    }

    // ---------- tasti ----------
    function touchKey(n, first) {
        if (won) return
        if (first) snd.tap()
        if (mode === "explore" || (mode === "raise" && ask !== "ordinal")) {
            // un solo gesto alza tutto fino al tasto toccato;
            // ritoccando l'ultimo alzato, quello torna giu'
            litFrom = 1
            litTo = first && litTo === n ? n - 1 : n
        } else if (mode === "raise") {
            var again = first && litTo === n && litFrom === n
            litFrom = again ? 1 : n
            litTo = again ? 0 : n
        } else if (mode === "add" && step === 0) {
            litTo = n
        } else if (mode === "add" && step === 1) {
            litTo = Math.max(numA, n)
        } else if (mode === "sub" && step === 0) {
            // toccando un tasto si abbassano quello e tutti quelli dopo
            litTo = Math.min(numA, n - 1)
            ghostFrom = litTo + 1
            ghostTo = numA
        }
    }

    function releaseKey(n) {
        if (won) return
        if (mode === "add" && step === 0) {
            if (litTo === numA) { snd.ok(); splitAt = numA; step = 1 }
            else { miss(); litTo = 0 }
        } else if (mode === "add" && step === 1) {
            if (litTo === numA + numB) { snd.ok(); step = 2; choices = makeChoices(answer, 20) }
            else if (litTo !== numA) { miss(); litTo = numA }
        } else if (mode === "sub" && step === 0) {
            if (numA - litTo === numB) {
                snd.ok(); step = 2; choices = makeChoices(answer, 20)
            } else if (litTo !== numA) {
                miss(); litTo = numA; ghostFrom = 21; ghostTo = 0
            }
        }
    }

    function miss() {
        snd.nope()
        wrong()
        keys.shake()
    }

    // "Fatto!" nell'attivita' "Alza i tasti"
    function confirmRaise() {
        if (won) return
        var good = ask === "ordinal" ? (litFrom === answer && litTo === answer)
                                     : (litTo === answer)
        if (good) { snd.win(); win() }
        else miss()
    }

    function tapChoice(n) {
        if (won || wrongChoices.indexOf(n) >= 0) return
        if (n !== answer) {
            wrongChoices = wrongChoices.concat([n])
            miss()
            return
        }
        peekTimer.stop()
        covered = false
        if (mode === "friends") {   // si riempiono i posti mancanti
            splitAt = numA
            litTo = numB
        }
        snd.win()
        win()
    }

    // ---------- scritte ----------
    function prompt() {
        switch (mode) {
        case "explore":
            return litTo > 0 ? litTo + "  -  " + words[litTo] : qsTr("Tocca un tasto!")
        case "read":
            return won ? qsTr("Sono %1: %2!").arg(answer).arg(words[answer]) : qsTr("Quanti sono?")
        case "raise":
            if (ask === "ordinal") return qsTr("Alza solo il tasto numero %1").arg(answer)
            if (ask === "word")
                return answer === 1 ? qsTr("Alza un tasto")
                                    : qsTr("Alza %1 tasti").arg(words[answer].toUpperCase())
            return answer === 1 ? qsTr("Alza 1 tasto") : qsTr("Alza %1 tasti").arg(answer)
        case "friends":
            return won ? numA + " + " + answer + " = " + numB
                       : qsTr("Quanti mancano per arrivare a %1?").arg(numB)
        case "add":
            if (won) return numA + " + " + numB + " = " + answer
            if (step === 0) return numA + " + " + numB + qsTr(":  alza %1").arg(numA)
            if (step === 1) return numA + " + " + numB + qsTr(":  aggiungi %1").arg(numB)
            return numA + " + " + numB + qsTr(":  quanti in tutto?")
        case "sub":
            if (won) return numA + " − " + numB + " = " + answer
            if (step === 0) return numA + " − " + numB + qsTr(":  togline %1").arg(numB)
            return numA + " − " + numB + qsTr(":  quanti restano?")
        }
        return ""
    }

    // ---------- scelta dell'attivita' ----------
    Item {
        id: menu
        anchors.fill: parent
        visible: g.mode === ""

        readonly property int cols: width >= 640 ? 3 : 2
        readonly property int rows: 6 / cols
        readonly property real cardW: Math.min(250, (width - (cols - 1) * 18) / cols)
        readonly property real cardH: Math.max(84, Math.min(170, (height - 180) / rows))

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(0, (menu.height - height) / 2 - 30)
            spacing: 18

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: question.implicitWidth + 44
                height: 52
                radius: 26
                color: "#E6FFFFFF"
                Text {
                    id: question
                    anchors.centerIn: parent
                    text: qsTr("Che cosa vuoi fare?")
                    font.pixelSize: 26
                    font.bold: true
                    color: Theme.title
                }
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: menu.cols
                spacing: 18

                Repeater {
                    model: g.activities
                    Rectangle {
                        id: card
                        required property var modelData
                        width: menu.cardW
                        height: menu.cardH
                        radius: 26
                        color: modelData.color
                        border.color: "white"
                        border.width: 4
                        scale: cardMa.pressed ? 0.93 : 1
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        Candy {}

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: card.height * 0.52; height: width; radius: width / 2
                                color: "white"
                                AppIcon {
                                    anchors.centerIn: parent
                                    name: card.modelData.icon
                                    size: parent.width * 0.74
                                }
                            }
                            Text {
                                width: card.width - 16
                                horizontalAlignment: Text.AlignHCenter
                                text: card.modelData.label
                                fontSizeMode: Text.HorizontalFit
                                minimumPixelSize: 11
                                font.pixelSize: 22
                                font.bold: true
                                color: "white"
                            }
                        }

                        MouseArea { id: cardMa; anchors.fill: parent; onClicked: g.choose(card.modelData.m) }
                    }
                }
            }
        }
    }

    // ---------- gioco ----------
    Item {
        id: play
        anchors.fill: parent
        visible: g.mode !== ""

        readonly property bool narrow: width < 760
        readonly property real controlsH: 104
        // in basso restano liberi il punteggio e il pulsante "avanti"
        readonly property real bottomSpace: narrow ? 104 : 4

        CandyButton {
            id: backBtn
            height: 54; textSize: 20
            icon: "puzzle"
            text: qsTr("Attività")
            color: "#AB47BC"
            onClicked: g.choose("")
        }

        CandyButton {   // mostra / nasconde le cifre sui tasti
            id: digitsBtn
            anchors.right: parent.right
            height: 54; textSize: 22
            text: "123"
            color: g.showDigits ? Theme.accent : "#90A4AE"
            onClicked: g.showDigits = !g.showDigits
        }

        Rectangle {
            id: promptPill
            anchors.horizontalCenter: parent.horizontalCenter
            y: play.narrow ? 66 : 0
            readonly property real maxW: play.narrow ? play.width
                                                     : play.width - 2 * Math.max(backBtn.width, digitsBtn.width) - 28
            width: Math.min(maxW, promptText.implicitWidth + 48)
            height: 62
            radius: 31
            color: "white"
            border.color: "#FFD54F"
            border.width: 3
            Candy { depth: 5 }
            Text {
                id: promptText
                anchors.centerIn: parent
                width: Math.min(implicitWidth, promptPill.maxW - 32)
                horizontalAlignment: Text.AlignHCenter
                text: g.prompt()
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 13
                font.pixelSize: 32
                font.bold: true
                color: Theme.text
            }
        }

        Item {
            id: stage
            anchors {
                top: promptPill.bottom; topMargin: 14
                left: parent.left; right: parent.right
                bottom: parent.bottom; bottomMargin: play.bottomSpace
            }

            KeyLine {
                id: keys
                width: parent.width
                height: Math.max(0, stage.height - play.controlsH - 14)

                litFrom: g.litFrom
                litTo: g.litTo
                splitAt: g.splitAt
                ghostFrom: g.ghostFrom
                ghostTo: g.ghostTo
                slotsTo: g.slotsTo
                covered: g.covered
                showDigits: g.showDigits
                interactive: !g.won && (g.mode === "explore" || g.mode === "raise"
                                        || ((g.mode === "add" || g.mode === "sub") && g.step < 2))
                onTouched: (n, first) => g.touchKey(n, first)
                onReleased: (n) => g.releaseKey(n)
                onPeekRequested: g.peek()
            }

            Item {
                id: controls
                width: parent.width
                height: play.controlsH
                // subito sotto la base dei tasti: l'insieme resta centrato
                y: (keys.height + keys.boardH) / 2 + 14

                // risposte: cifra e nome del numero
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14
                    Repeater {
                        model: g.choices
                        Rectangle {
                            id: choice
                            required property int modelData
                            readonly property bool failed: g.wrongChoices.indexOf(modelData) >= 0
                            readonly property bool solved: g.won && modelData === g.answer
                            width: Math.min(136, (controls.width - 3 * 14) / 4)
                            height: 96
                            radius: 24
                            color: solved ? Theme.accent : Theme.panel
                            border.color: solved ? "white" : Theme.boardLine
                            border.width: 4
                            opacity: failed || (g.won && !solved) ? 0.35 : 1
                            scale: solved ? 1.08 : (choiceMa.pressed && !failed ? 0.92 : 1)
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                            Candy {}
                            Column {
                                anchors.centerIn: parent
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: choice.modelData
                                    font.pixelSize: 44
                                    font.bold: true
                                    color: choice.solved ? "white" : Theme.title
                                }
                                Text {
                                    width: choice.width - 12
                                    horizontalAlignment: Text.AlignHCenter
                                    text: g.words[choice.modelData]
                                    fontSizeMode: Text.HorizontalFit
                                    minimumPixelSize: 8
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: choice.solved ? "white" : Theme.text
                                }
                            }
                            MouseArea { id: choiceMa; anchors.fill: parent; onClicked: g.tapChoice(choice.modelData) }
                        }
                    }
                }

                CandyButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    visible: g.mode === "raise" && !g.won
                    icon: "ui/check"
                    text: qsTr("Fatto!")
                    onClicked: g.confirmRaise()
                }

                CandyButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    visible: g.mode === "explore"
                    icon: "ui/restart"
                    text: qsTr("Tutti giù")
                    color: Theme.dirLeft
                    onClicked: { snd.tap(); g.litTo = 0 }
                }
            }
        }
    }
}
