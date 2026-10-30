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
    property int score: 0        // faccine totali in questa sessione (si azzera uscendo)
    property int mistakes: 0     // errori nel livello in corso (per le faccine)

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

    Rectangle { anchors.fill: parent; color: Theme.background }

    // ---------- piccoli bottoni riutilizzabili ----------
    component IconButton: Rectangle {
        property alias text: lbl.text
        signal clicked()
        width: 66; height: 66; radius: 33
        color: Theme.panel
        border.color: Theme.boardLine
        border.width: 3
        scale: ibma.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        Text { id: lbl; anchors.centerIn: parent; font.pixelSize: 30; color: Theme.text }
        MouseArea { id: ibma; anchors.fill: parent; onClicked: parent.clicked() }
    }

    component BigButton: Rectangle {
        property string symbol: ""
        property color  bg: Theme.accent
        property bool   on: true
        signal clicked()
        implicitWidth: 116; implicitHeight: 116
        radius: 28
        color: bg
        opacity: on ? 1 : 0.28
        scale: bbma.pressed && on ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        Text { anchors.centerIn: parent; text: symbol; font.pixelSize: 50; color: "white" }
        MouseArea { id: bbma; anchors.fill: parent; enabled: parent.on; onClicked: parent.clicked() }
    }

    // ---------- intestazione ----------
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 96

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
            text: "←"
            onClicked: root.exitRequested()
        }

        Column {
            anchors.centerIn: parent
            spacing: 2

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Livello ") + (engine.levelIndex + 1)
                    font.pixelSize: 28
                    font.bold: true
                    color: Theme.text
                }
                ScoreBar {
                    anchors.verticalCenter: parent.verticalCenter
                    value: root.score
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
                text: [root.age, root.playerName].filter(function (s) { return s !== "" }).join("   •   ")
                font.pixelSize: 18
                color: Theme.text
                opacity: 0.55
            }
        }

        IconButton {   // cambia / inserisci il nome del bambino
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 98
            text: "👤"
            onClicked: namePrompt.visible = true
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20
            text: "🔄"
            onClicked: { sndTap.play(); engine.loadLevel(engine.levelIndex) }
        }
    }

    // ---------- tabellone ----------
    Board {
        id: board
        engine: engine
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: controls.top
            margins: 16
        }
    }

    // ---------- controlli in basso ----------
    Column {
        id: controls
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 20 }
        spacing: 16

        CommandStrip {
            id: strip
            engine: engine
            width: parent.width
        }

        Item {
            width: parent.width
            height: pad.implicitHeight

            DirectionPad {
                id: pad
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                active: engine.state === PathEngine.Editing
                onMoved: (d) => { sndTap.play(); engine.addCommand(d) }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 22

                BigButton {          // cestino
                    symbol: "🗑"
                    bg: Theme.danger
                    visible: engine.commands.length > 0 && engine.state === PathEngine.Editing
                    onClicked: { sndTap.play(); engine.clearCommands() }
                }

                BigButton {          // vai / ferma
                    symbol: engine.state === PathEngine.Running ? "■" : "▶"
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
                    symbol: "➜"
                    bg: Theme.dirUp
                    visible: engine.state === PathEngine.Won
                    onClicked: { sndTap.play(); root.goNext() }
                }
            }
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
