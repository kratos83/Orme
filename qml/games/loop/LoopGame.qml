import QtQuick
import Giochi

// "Ancora!" - il concetto di CICLO / RIPETIZIONE.
// C'e' una sola azione (il salto): il bambino sceglie QUANTE VOLTE ripeterla
// con la manopola dei numeri, poi preme "vai". Il coniglio salta quel numero
// di volte: se arriva esatto sulla carota ha vinto, altrimenti si riprova.
GameScaffold {
    id: scaffold
    title: qsTr("Ancora!")
    age: qsTr("4-5 anni")
    showNext: won

    onRestartRequested: load(levelIndex)
    onNextRequested: goNext()
    onWinFinished: goNext()          // dopo la festa si passa da solo

    // quante ninfee di distanza c'e' la carota, livello per livello
    readonly property var levels: [2, 3, 2, 4, 3, 5, 4, 6]

    property int  levelIndex: 0
    property int  target: 2
    property int  pos: 0          // su quale ninfea e' il coniglio (0 = partenza)
    property int  count: 1        // numero di ripetizioni scelto
    property bool hopping: false
    property bool won: false
    property int  hopsLeft: 0
    property int  mistakes: 0

    SoundBank { id: snd }

    function load(i) {
        levelIndex = ((i % levels.length) + levels.length) % levels.length
        target = levels[levelIndex]
        pos = 0
        count = 1
        hopping = false
        won = false
        hopsLeft = 0
        mistakes = 0
    }

    function nextMsg() {
        return qsTr("Sei al livello ") + (((levelIndex + 1) % levels.length) + 1)
    }
    function goNext() {
        if (!won) return
        load(levelIndex + 1)
    }

    function go() {
        if (hopping || won || count <= 0)
            return
        hopping = true
        hopsLeft = count
        hopTimer.start()
    }

    Timer {
        id: hopTimer
        interval: 480
        repeat: true
        running: false
        onTriggered: {
            scaffold.pos += 1
            scaffold.hopsLeft -= 1
            snd.ok()
            if (scaffold.hopsLeft <= 0) {
                stop()
                scaffold.hopping = false
                if (scaffold.pos === scaffold.target) {
                    scaffold.won = true
                    snd.win()
                    scaffold.reward(3 - Math.min(2, scaffold.mistakes), scaffold.nextMsg())
                } else {
                    scaffold.mistakes += 1
                    snd.nope()
                    scaffold.oops()
                    backTimer.start()
                }
            }
        }
    }

    Timer { id: backTimer; interval: 950; onTriggered: scaffold.pos = 0 }

    Component.onCompleted: load(0)

    // ---------- pezzi riutilizzabili ----------
    component StepBtn: Rectangle {
        property alias glyph: sb.text
        signal clicked()
        width: 88; height: 88; radius: 20
        color: enabled ? Theme.dirLeft : "#D8CBB0"
        scale: sbma.pressed && enabled ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        Text { id: sb; anchors.centerIn: parent; font.pixelSize: 48; font.bold: true; color: "white" }
        MouseArea { id: sbma; anchors.fill: parent; enabled: parent.enabled; onClicked: parent.clicked() }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        // ===== la pista con le ninfee =====
        Item {
            id: track
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height * 0.55

            readonly property int  slotsCount: scaffold.target + 1
            readonly property real slotW: Math.min(120, width / Math.max(1, track.slotsCount))
            readonly property real x0: (width - slotW * track.slotsCount) / 2
            function cx(i) { return x0 + slotW * i + slotW / 2 }

            Repeater {
                model: track.slotsCount
                Rectangle {
                    width: track.slotW * 0.8
                    height: width
                    radius: width / 2
                    color: Theme.boardFill
                    border.color: Theme.boardLine
                    border.width: 4
                    x: track.cx(index) - width / 2
                    y: track.height / 2 - height / 2

                    Text {
                        anchors.centerIn: parent
                        visible: index === scaffold.target
                        text: "🥕"
                        font.pixelSize: parent.width * 0.6
                    }
                }
            }

            Text {
                id: bunny
                text: "🐰"
                font.pixelSize: track.slotW * 0.7
                x: track.cx(scaffold.pos) - width / 2
                y: track.height / 2 - height / 2
                Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutQuad } }

                SequentialAnimation on scale {
                    running: scaffold.hopping
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.15; duration: 190 }
                    NumberAnimation { from: 1.15; to: 1.0; duration: 190 }
                }
            }
        }

        // ===== i comandi =====
        Row {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 20 }
            spacing: 24

            // carta azione: cosa viene ripetuto (il salto)
            Rectangle {
                width: 120; height: 120; radius: 24
                color: Theme.dirDown
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "🦘"; font.pixelSize: 64 }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "×"
                font.pixelSize: 48
                color: Theme.text
            }

            StepBtn {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "−"
                enabled: !scaffold.hopping && !scaffold.won && scaffold.count > 1
                onClicked: { snd.tap(); scaffold.count = Math.max(1, scaffold.count - 1) }
            }

            Rectangle {
                width: 100; height: 88; radius: 20
                color: Theme.panel
                border.color: Theme.boardLine; border.width: 3
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: scaffold.count
                    font.pixelSize: 56
                    font.bold: true
                    color: Theme.text
                }
            }

            StepBtn {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "+"
                enabled: !scaffold.hopping && !scaffold.won && scaffold.count < 6
                onClicked: { snd.tap(); scaffold.count = Math.min(6, scaffold.count + 1) }
            }

            // vai
            Rectangle {
                width: 120; height: 120; radius: 24
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.accent
                opacity: (scaffold.hopping || scaffold.won) ? 0.3 : 1
                scale: goma.pressed && !scaffold.hopping && !scaffold.won ? 0.92 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }
                Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 60; color: "white" }
                MouseArea {
                    id: goma
                    anchors.fill: parent
                    enabled: !scaffold.hopping && !scaffold.won
                    onClicked: { snd.tap(); scaffold.go() }
                }
            }
        }
    }
}
