// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Regioni d'Italia: quiz a 4 risposte. A volte si chiede il capoluogo di
// una regione, a volte la regione di un capoluogo.
MiniGame {
    id: g
    title: qsTr("Regioni d'Italia")
    age: qsTr("8-10 anni")
    levelCount: 12

    readonly property var regions: [
        { r: qsTr("Valle d'Aosta"), c: qsTr("Aosta") },
        { r: qsTr("Piemonte"), c: qsTr("Torino") },
        { r: qsTr("Liguria"), c: qsTr("Genova") },
        { r: qsTr("Lombardia"), c: qsTr("Milano") },
        { r: qsTr("Trentino-Alto Adige"), c: qsTr("Trento") },
        { r: qsTr("Friuli Venezia Giulia"), c: qsTr("Trieste") },
        { r: qsTr("Veneto"), c: qsTr("Venezia") },
        { r: qsTr("Emilia-Romagna"), c: qsTr("Bologna") },
        { r: qsTr("Toscana"), c: qsTr("Firenze") },
        { r: qsTr("Umbria"), c: qsTr("Perugia") },
        { r: qsTr("Sardegna"), c: qsTr("Cagliari") },
        { r: qsTr("Marche"), c: qsTr("Ancona") },
        { r: qsTr("Lazio"), c: qsTr("Roma") },
        { r: qsTr("Abruzzo"), c: qsTr("L'Aquila") },
        { r: qsTr("Campania"), c: qsTr("Napoli") },
        { r: qsTr("Molise"), c: qsTr("Campobasso") },
        { r: qsTr("Puglia"), c: qsTr("Bari") },
        { r: qsTr("Basilicata"), c: qsTr("Potenza") },
        { r: qsTr("Calabria"), c: qsTr("Catanzaro") },
        { r: qsTr("Sicilia"), c: qsTr("Palermo") }
    ]

    property int targetIndex: 0
    property string direction: "toCap"   // "toCap" (regione -> capoluogo) o "toReg" (capoluogo -> regione)
    property var choices: []             // 4 indici in "regions", uno dei quali è targetIndex
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function shuffle(a) {
        var r = a.slice()
        for (var k = r.length - 1; k > 0; k--) {
            var j = Math.floor(Math.random() * (k + 1))
            var t = r[k]; r[k] = r[j]; r[j] = t
        }
        return r
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        direction = Math.random() < 0.5 ? "toCap" : "toReg"
        targetIndex = Math.floor(Math.random() * regions.length)
        var pool = []
        for (var k = 0; k < regions.length; k++) if (k !== targetIndex) pool.push(k)
        pool = shuffle(pool).slice(0, 3)
        pool.push(targetIndex)
        choices = shuffle(pool)
    }

    function pick(idx) {
        if (answered) return
        if (idx === targetIndex) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
        }
    }

    function questionText() {
        if (regions.length === 0) return ""
        return direction === "toCap"
            ? qsTr("Qual è il capoluogo di") + " " + regions[targetIndex].r + "?"
            : qsTr("Di quale regione è capoluogo") + " " + regions[targetIndex].c + "?"
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Column {
            anchors.centerIn: parent
            spacing: 30
            width: Math.min(parent.width - 40, 560)

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: g.questionText()
                font.pixelSize: 28
                font.bold: true
                color: Theme.text
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 2
                rowSpacing: 16
                columnSpacing: 16

                Repeater {
                    model: g.choices
                    Rectangle {
                        id: opt
                        required property int modelData
                        required property int index
                        width: 260; height: 84; radius: 18
                        color: Theme.playColors[index % Theme.playColors.length]
                        opacity: g.answered && opt.modelData !== g.targetIndex ? 0.4 : 1
                        scale: optMa.pressed ? 0.95 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text {
                            anchors.centerIn: parent
                            anchors.margins: 8
                            width: parent.width - 16
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: g.direction === "toCap" ? g.regions[opt.modelData].c : g.regions[opt.modelData].r
                            font.pixelSize: 20
                            font.bold: true
                            color: "white"
                        }
                        MouseArea { id: optMa; anchors.fill: parent; enabled: !g.won; onClicked: g.pick(opt.modelData) }
                    }
                }
            }
        }
    }
}
