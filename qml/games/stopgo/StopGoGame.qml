import QtQuick
import Orme

// "Un, due, tre, stella!" - il concetto di STOP/GO (evento/condizione).
// Un semaforo cambia colore da solo: si puo' avanzare di una casella verso
// la stella solo col semaforo verde. Muoversi col rosso e' un errore e si
// torna alla partenza.
GameScaffold {
    id: scaffold
    title: qsTr("Un, due, tre, stella!")
    age: qsTr("3-4 anni")
    showNext: won

    onRestartRequested: load(levelIndex)
    onNextRequested: goNext()
    onWinFinished: goNext()

    readonly property var levels: [2, 3, 2, 4, 3, 5, 4, 6]

    property int  levelIndex: 0
    property int  target: 2
    property int  pos: 0
    property bool green: true
    property bool won: false
    property bool caught: false
    property int  mistakes: 0

    SoundBank { id: snd }

    function nextMsg() {
        return qsTr("Sei al livello ") + (((levelIndex + 1) % levels.length) + 1)
    }
    function goNext() {
        if (!won) return
        load(levelIndex + 1)
    }

    function load(i) {
        levelIndex = ((i % levels.length) + levels.length) % levels.length
        target = levels[levelIndex]
        pos = 0
        green = true
        won = false
        caught = false
        mistakes = 0
        lightTimer.restart()
    }

    function scheduleLight() {
        lightTimer.interval = scaffold.green
            ? (1400 + Math.random() * 1200)
            : (1000 + Math.random() * 1000)
    }

    Timer {
        id: lightTimer
        interval: 1800
        running: !scaffold.won
        repeat: true
        onTriggered: {
            scaffold.green = !scaffold.green
            scaffold.scheduleLight()
        }
    }

    function step() {
        if (won || caught) return
        if (!green) {
            caught = true
            mistakes += 1
            snd.nope()
            oops()
            backTimer.start()
            return
        }
        pos += 1
        snd.ok()
        if (pos === target) {
            won = true
            snd.win()
            reward(3 - Math.min(2, mistakes), nextMsg())
        }
    }

    Timer { id: backTimer; interval: 950; onTriggered: { scaffold.pos = 0; scaffold.caught = false } }

    Component.onCompleted: load(0)

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        // ===== semaforo =====
        Rectangle {
            id: light
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
            width: 84; height: 84; radius: 42
            color: scaffold.green ? Theme.accent : Theme.danger
            border.color: Theme.boardLine
            border.width: 4

            Text {
                anchors.centerIn: parent
                text: scaffold.green ? "🟢" : "🔴"
                font.pixelSize: 46
            }
        }

        // ===== pista =====
        Item {
            id: track
            anchors { left: parent.left; right: parent.right; top: light.bottom; topMargin: 18 }
            height: parent.height * 0.5

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
                        text: "⭐"
                        font.pixelSize: parent.width * 0.6
                    }
                }
            }

            Text {
                id: walker
                text: "🚶"
                font.pixelSize: track.slotW * 0.7
                x: track.cx(scaffold.pos) - width / 2
                y: track.height / 2 - height / 2
                Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutQuad } }
            }
        }

        // ===== pulsante "Cammina" =====
        Rectangle {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 24 }
            width: 160; height: 120; radius: 24
            color: Theme.accent
            opacity: (scaffold.won || scaffold.caught) ? 0.4 : 1
            scale: goma.pressed && !scaffold.won && !scaffold.caught ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: 80 } }
            Text { anchors.centerIn: parent; text: "👣"; font.pixelSize: 60 }
            MouseArea {
                id: goma
                anchors.fill: parent
                enabled: !scaffold.won && !scaffold.caught
                onClicked: scaffold.step()
            }
        }
    }
}
