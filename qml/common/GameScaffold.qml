// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

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
    property string scenery: "prato" // sfondo, vedi Scenery.qml
    property string playerName: ""   // nome del bambino (inserito all'inizio)
    property bool showNext: false
    property bool showRestart: true
    property int  contentMargins: 16 // 0 = il gioco arriva fino ai bordi
    property int  score: 0        // stelle totali in questa sessione di gioco

    signal exitRequested()
    signal restartRequested()
    signal nextRequested()
    signal winFinished()          // la festa e' finita (utile per auto-avanzare)

    // vittoria di un livello: assegna le stelle (1-3) e fa partire la festa,
    // con un messaggio tipo "Sei al livello 5".
    function reward(stars, message) {
        var s = Math.max(1, Math.min(3, stars || 1))
        score += s
        winOverlay.celebrate(s, message || "")
    }
    function celebrate() { winOverlay.celebrate(0, "") }
    function oops()      { oopsOverlay.show() }

    Scenery { theme: root.scenery }

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

        TitlePill {
            anchors.centerIn: parent
            maxWidth: header.width - 360
            title: root.title
            titleSize: 28
            subtitle: [root.age, root.playerName].filter(function (s) { return s !== "" }).join("   •   ")
        }

        CircleButton {   // cambia / inserisci il nome del bambino
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.showRestart ? 98 : 20
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
            margins: root.contentMargins
        }
    }

    // grande "avanti" quando il livello e' vinto
    Rectangle {
        id: nextBtn
        visible: root.showNext
        width: 122; height: 122
        radius: width / 2
        color: Theme.accent
        border.color: "white"
        border.width: 5
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28

        SequentialAnimation on scale {
            running: root.showNext
            loops: Animation.Infinite
            NumberAnimation { from: 1.0;  to: 1.08; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.08; to: 1.0;  duration: 600; easing.type: Easing.InOutSine }
        }

        Candy { depth: 8 }
        AppIcon { anchors.centerIn: parent; name: "ui/play"; size: 66 }
        MouseArea { anchors.fill: parent; onClicked: root.nextRequested() }
    }

    // punteggio a stelle, in basso a sinistra
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
