// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// Cornice comune a tutti i mini-giochi:
//  - schermata iniziale per il nome del bambino
//  - sfondo
//  - intestazione con "indietro" (a sinistra) e "ricomincia" (a destra),
//    titolo, eta' consigliata e nome del bambino
//  - un'area centrale dove il gioco mette il suo contenuto (proprieta' default)
//  - un grande pulsante "avanti" che pulsa quando il gioco e' stato vinto
//  - gli overlay di festa ("BRAVO") e di errore ("Ops! Riprova"), richiamabili
//    con celebrate() e oops()
//
// Un gioco tipico ha come radice proprio un GameScaffold e gestisce
// onRestartRequested / onNextRequested; exitRequested sale fino a Main.qml.
// Il punteggio (score) vive solo qui: uscendo, il gioco viene distrutto e
// ricreato, quindi riparte da zero con un nuovo nome.
Item {
    id: root

    default property alias content: slot.data

    property string title: ""
    property string age: ""          // fascia d'eta', es. "3-5 anni"
    property string playerName: ""   // nome del bambino (inserito all'inizio)
    property bool showNext: false
    property bool showRestart: true
    property int  score: 0        // faccine totali in questa sessione di gioco

    signal exitRequested()
    signal restartRequested()
    signal nextRequested()
    signal winFinished()          // la festa e' finita (utile per auto-avanzare)

    // vittoria di un livello: assegna le faccine (1-3) e fa partire la festa,
    // con un messaggio tipo "Sei al livello 5".
    function reward(stars, message) {
        var s = Math.max(1, Math.min(3, stars || 1))
        score += s
        winOverlay.celebrate(s, message || "")
    }
    function celebrate() { winOverlay.celebrate(0, "") }
    function oops()      { oopsOverlay.show() }

    Rectangle { anchors.fill: parent; color: Theme.background }

    component RoundBtn: Rectangle {
        property alias glyph: t.text
        signal clicked()
        width: 66; height: 66; radius: 33
        color: Theme.panel
        border.color: Theme.boardLine
        border.width: 3
        scale: rbma.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        Text { id: t; anchors.centerIn: parent; font.pixelSize: 30; color: Theme.text }
        MouseArea { id: rbma; anchors.fill: parent; onClicked: parent.clicked() }
    }

    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 96

        RoundBtn {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
            glyph: "←"
            onClicked: root.exitRequested()
        }

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.title
                font.pixelSize: 26
                font.bold: true
                color: Theme.text
                opacity: 0.6
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

        RoundBtn {   // cambia / inserisci il nome del bambino
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.showRestart ? 98 : 20
            glyph: "👤"
            onClicked: namePrompt.visible = true
        }

        RoundBtn {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20
            glyph: "↻"
            visible: root.showRestart
            onClicked: root.restartRequested()
        }
    }

    Item {
        id: slot
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 16
        }
    }

    // grande "avanti" quando il livello e' vinto
    Rectangle {
        id: nextBtn
        visible: root.showNext
        width: 122; height: 122
        radius: 28
        color: Theme.accent
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28

        SequentialAnimation on scale {
            running: root.showNext
            loops: Animation.Infinite
            NumberAnimation { from: 1.0;  to: 1.08; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.08; to: 1.0;  duration: 600; easing.type: Easing.InOutSine }
        }

        Text { anchors.centerIn: parent; text: "➔"; font.pixelSize: 56; color: "white" }
        MouseArea { anchors.fill: parent; onClicked: root.nextRequested() }
    }

    // punteggio a faccine, in basso a sinistra
    ScoreBar {
        value: root.score
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
    }

    Celebration {
        id: winOverlay
        onFinished: root.winFinished()
    }
    TryAgainBanner { id: oopsOverlay }

    // schermata iniziale: inserimento del nome del bambino
    NamePrompt {
        id: namePrompt
        onAccepted: (n) => root.playerName = n
    }
}
