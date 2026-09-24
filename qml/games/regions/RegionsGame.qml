// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Regioni d'Italia: leggi il nome (della regione o del suo capoluogo) e
// tocca la regione giusta sulla mappa (ItalyMap.qml, schematica: blocchi
// grandi al posto di confini reali, per bersagli touch adatti ai bambini).
MiniGame {
    id: g
    title: qsTr("Regioni d'Italia")
    age: qsTr("8-10 anni")
    levelCount: 12

    readonly property var regions: [
        { id: "valledaosta", r: qsTr("Valle d'Aosta"), c: qsTr("Aosta") },
        { id: "piemonte", r: qsTr("Piemonte"), c: qsTr("Torino") },
        { id: "liguria", r: qsTr("Liguria"), c: qsTr("Genova") },
        { id: "lombardia", r: qsTr("Lombardia"), c: qsTr("Milano") },
        { id: "trentino", r: qsTr("Trentino-Alto Adige"), c: qsTr("Trento") },
        { id: "friuli", r: qsTr("Friuli Venezia Giulia"), c: qsTr("Trieste") },
        { id: "veneto", r: qsTr("Veneto"), c: qsTr("Venezia") },
        { id: "emilia", r: qsTr("Emilia-Romagna"), c: qsTr("Bologna") },
        { id: "toscana", r: qsTr("Toscana"), c: qsTr("Firenze") },
        { id: "umbria", r: qsTr("Umbria"), c: qsTr("Perugia") },
        { id: "sardegna", r: qsTr("Sardegna"), c: qsTr("Cagliari") },
        { id: "marche", r: qsTr("Marche"), c: qsTr("Ancona") },
        { id: "lazio", r: qsTr("Lazio"), c: qsTr("Roma") },
        { id: "abruzzo", r: qsTr("Abruzzo"), c: qsTr("L'Aquila") },
        { id: "campania", r: qsTr("Campania"), c: qsTr("Napoli") },
        { id: "molise", r: qsTr("Molise"), c: qsTr("Campobasso") },
        { id: "puglia", r: qsTr("Puglia"), c: qsTr("Bari") },
        { id: "basilicata", r: qsTr("Basilicata"), c: qsTr("Potenza") },
        { id: "calabria", r: qsTr("Calabria"), c: qsTr("Catanzaro") },
        { id: "sicilia", r: qsTr("Sicilia"), c: qsTr("Palermo") }
    ]

    property int targetIndex: 0
    property string mode: "byName"   // "byName" (mostra la regione) o "byCapital" (mostra il capoluogo)
    property string wrongFlashId: ""
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        wrongFlashId = ""
        mode = Math.random() < 0.5 ? "byName" : "byCapital"
        targetIndex = Math.floor(Math.random() * regions.length)
    }

    Timer { id: clearWrongFlash; interval: 450; onTriggered: g.wrongFlashId = "" }

    function pick(id) {
        if (answered) return
        if (id === regions[targetIndex].id) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
            wrongFlashId = id
            clearWrongFlash.restart()
        }
    }

    function questionText() {
        if (regions.length === 0) return ""
        var t = regions[targetIndex]
        return mode === "byCapital"
            ? qsTr("Tocca sulla mappa la regione con capoluogo") + " " + t.c
            : qsTr("Tocca sulla mappa:") + " " + t.r
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Text {
            id: prompt
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: g.questionText()
            font.pixelSize: 24
            font.bold: true
            color: Theme.text
        }

        Item {
            id: mapHolder
            anchors { top: prompt.bottom; topMargin: 14; left: parent.left; right: parent.right; bottom: parent.bottom }

            ItalyMap {
                id: map
                anchors.centerIn: parent
                scale: Math.min(mapHolder.width / map.implicitWidth, mapHolder.height / map.implicitHeight, 1)
                transformOrigin: Item.Center
                correctId: g.regions[g.targetIndex].id
                wrongId: g.wrongFlashId
                answered: g.answered
                onRegionTapped: (id) => g.pick(id)
            }
        }
    }
}
