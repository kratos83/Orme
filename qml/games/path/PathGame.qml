// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtMultimedia
import Orme

// Schermata del gioco "Il percorso".
Item {
    id: root
    signal exitRequested()

    PathEngine { id: engine }

    readonly property string age: qsTr("3-5 anni")
    property string playerName: ""   // inserito nella schermata iniziale
    property int score: 0        // stelle totali in questa sessione (si azzera uscendo)
    property int mistakes: 0     // errori nel livello in corso (per le stelle)

    function nextMsg() {
        return qsTr("Sei al livello ") + (((engine.levelIndex + 1) % engine.levelCount) + 1)
    }
    // dopo la festa (o col pulsante) si passa da soli al livello successivo
    function goNext() {
        if (engine.state !== PathEngine.Won) return
        engine.nextLevel()
    }

    // ---------- suoni ----------
    SoundEffect { id: sndTap;  source: "qrc:/qt/qml/Orme/assets/sounds/tap.wav" }
    SoundEffect { id: sndStep; source: "qrc:/qt/qml/Orme/assets/sounds/step.wav" }
    SoundEffect { id: sndWin;  source: "qrc:/qt/qml/Orme/assets/sounds/win.wav" }
    SoundEffect { id: sndBump; source: "qrc:/qt/qml/Orme/assets/sounds/bump.wav" }

    Connections {
        target: engine
        function onStepPlayed(i) { sndStep.play() }
        function onWon() {
            var stars = Math.max(1, 3 - Math.min(2, root.mistakes))
            root.score += stars
            sndWin.play()
            celebration.celebrate(stars, root.nextMsg())
        }
        // sbaglia (sbatte o la sequenza non arriva alla mela):
        // "riprova", poi si azzera tutto da solo e si ricomincia a comporre
        function onMistake() {
            root.mistakes += 1
            sndBump.play(); tryAgain.show(); clearLater.restart()
        }
        // nuovo livello (avanti o ricomincia): azzera gli errori
        function onLevelChanged() { root.mistakes = 0 }
    }

    // pausa breve per far vedere il messaggio, poi svuota la sequenza
    // (clearCommands riporta anche il personaggio alla partenza)
    Timer { id: clearLater; interval: 1300; onTriggered: engine.clearCommands() }

    Scenery { theme: "prato" }

    // ---------- piccoli bottoni riutilizzabili ----------
    component BigButton: Rectangle {
        property string symbol: ""
        property color  bg: Theme.accent
        property bool   on: true
        signal clicked()
        implicitWidth: root.bigSize; implicitHeight: root.bigSize
        radius: 32
        color: bg
        border.color: "white"
        border.width: 5
        opacity: on ? 1 : 0.28
        scale: bbma.pressed && on ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        Candy { depth: 8 }
        AppIcon { anchors.centerIn: parent; name: symbol; size: parent.width * 0.5 }
        MouseArea { id: bbma; anchors.fill: parent; enabled: parent.on; onClicked: parent.clicked() }
    }

    // ---------- intestazione ----------
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 96

        CircleButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
            icon: "ui/back"
            color: Theme.dirLeft
            onClicked: root.exitRequested()
        }

        Rectangle {   // targa: livello, stelle, età e nome
            anchors.centerIn: parent
            width: titleCol.width + 56
            height: titleCol.height + 10
            radius: 30
            color: "white"
            Candy { depth: 5 }

            Column {
                id: titleCol
                anchors.centerIn: parent

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Livello ") + (engine.levelIndex + 1)
                        font.pixelSize: 28
                        font.bold: true
                        color: Theme.title
                    }
                    ScoreBar {
                        anchors.verticalCenter: parent.verticalCenter
                        value: root.score
                        scale: 0.8
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== ""
                    text: [root.age, root.playerName].filter(function (s) { return s !== "" }).join("   •   ")
                    font.pixelSize: 16
                    color: Theme.text
                }
            }
        }

        CircleButton {   // cambia / inserisci il nome del bambino
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 98
            icon: "ui/person"
            color: "#AB47BC"
            onClicked: namePrompt.visible = true
        }

        CircleButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20
            icon: "ui/restart"
            color: Theme.dirUp
            onClicked: { sndTap.play(); engine.loadLevel(engine.levelIndex) }
        }
    }

    // ---------- disposizione ----------
    // Schermi larghi: tabellone grande a sinistra, frecce e pulsanti a destra,
    // striscia dei comandi in basso. Schermi alti: tutto uno sotto l'altro.
    readonly property bool wide: width > height * 1.1
    // spazio verticale disponibile fra intestazione e striscia
    readonly property real sideHeight: height - header.height - strip.height - 52
    readonly property real bigSize: wide ? Math.max(72, Math.min(116, sideHeight * 0.24)) : 116
    readonly property real padButton: wide
        ? Math.max(44, Math.min(Theme.touch, (sideHeight - bigSize - 36) / 3))
        : Theme.touch
    readonly property real sideWidth: Math.max(padButton * 3 + 20, bigSize * 2 + 22)

    // ---------- tabellone ----------
    Board {
        id: board
        engine: engine
        x: 16
        y: header.height + 8
        width: root.width - 32 - (root.wide ? root.sideWidth + 20 : 0)
        height: Math.max(0, strip.y - y - 16)
    }

    CommandStrip {
        id: strip
        engine: engine
        x: 20
        width: root.width - 40
        height: implicitHeight
        y: root.wide ? root.height - height - 20 : pad.y - height - 16
    }

    // ---------- comandi ----------
    DirectionPad {
        id: pad
        btn: root.padButton
        width: implicitWidth
        height: implicitHeight
        x: root.wide ? root.width - 20 - (root.sideWidth + width) / 2 : 20
        y: root.wide
           ? header.height + 8 + Math.max(0, (root.sideHeight - height - root.bigSize - 26) / 2)
           : root.height - height - 24
        active: engine.state === PathEngine.Editing
        onMoved: (d) => { sndTap.play(); engine.addCommand(d) }
    }

    Row {
        spacing: 22
        x: root.wide ? root.width - 20 - (root.sideWidth + width) / 2 : root.width - 20 - width
        y: root.wide ? pad.y + pad.height + 22 : pad.y + (pad.height - height) / 2

        BigButton {          // cestino
            symbol: "ui/trash"
            bg: Theme.danger
            visible: engine.commands.length > 0 && engine.state === PathEngine.Editing
            onClicked: { sndTap.play(); engine.clearCommands() }
        }

        BigButton {          // vai / ferma
            symbol: engine.state === PathEngine.Running ? "ui/stop" : "ui/play"
            bg: Theme.accent
            on: engine.commands.length > 0 && engine.state !== PathEngine.Mistake
            onClicked: {
                sndTap.play()
                if (engine.state === PathEngine.Running)
                    engine.stop()
                else
                    engine.run()
            }
        }

        BigButton {          // livello successivo (appare quando ha vinto)
            symbol: "ui/next"
            bg: Theme.dirUp
            visible: engine.state === PathEngine.Won
            onClicked: { sndTap.play(); root.goNext() }
        }
    }

    Celebration {
        id: celebration
        onFinished: root.goNext()      // finita la festa, avanti da soli
    }
    TryAgainBanner { id: tryAgain }

    // schermata iniziale: nome del bambino
    NamePrompt {
        id: namePrompt
        onAccepted: (n) => root.playerName = n
    }
}
