import QtQuick
import Orme

// "Il gioco delle posizioni" - il concetto di ESEGUIRE IL COMANDO mostrato.
// In alto compare una posa (animale o supereroe), sotto tre scelte: tocca
// quella uguale al comando.
MiniGame {
    id: g
    title: qsTr("Il gioco delle posizioni")
    age: qsTr("3-4 anni")
    levelCount: 10

    readonly property var poses: ["🐸", "🦁", "🦅", "🐻", "🦸", "🥷", "🤸", "🕺"]

    property string command: "🐸"
    property var choices: ["🐸", "🦁", "🦅"]

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function shuffle(a) {
        var r = a.slice()
        for (var i = r.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1))
            var t = r[i]; r[i] = r[j]; r[j] = t
        }
        return r
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0

        var pool = shuffle(poses)
        command = pool[0]
        choices = shuffle([pool[0], pool[1], pool[2]])
    }

    function pick(p) {
        if (g.won) return
        if (p === g.command) {
            snd.win(); win()
        } else {
            g.mistakes += 1
            snd.nope()
            shake.restart()
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        // ===== comando =====
        Rectangle {
            id: commandCard
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 12 }
            width: 190; height: 190
            radius: 32
            color: Theme.panel
            border.color: Theme.accent
            border.width: 5
            Text { anchors.centerIn: parent; text: g.command; font.pixelSize: 120 }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: commandCard.y + commandCard.height + 10
            text: "▼"
            font.pixelSize: 34
            color: Theme.text
            opacity: 0.5
        }

        // ===== scelte =====
        Row {
            id: choiceRow
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 30 }
            spacing: 30

            SequentialAnimation {
                id: shake
                NumberAnimation { target: choiceRow; property: "rotation"; to: -6; duration: 55 }
                NumberAnimation { target: choiceRow; property: "rotation"; to:  6; duration: 55 }
                NumberAnimation { target: choiceRow; property: "rotation"; to:  0; duration: 55 }
            }

            Repeater {
                model: g.choices
                Rectangle {
                    id: card
                    width: 150; height: 150
                    radius: 26
                    color: Theme.panel
                    border.color: Theme.boardLine
                    border.width: 3

                    required property string modelData

                    scale: cardMa.pressed && !g.won ? 0.93 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Text { anchors.centerIn: parent; text: card.modelData; font.pixelSize: 90 }

                    MouseArea {
                        id: cardMa
                        anchors.fill: parent
                        enabled: !g.won
                        onClicked: g.pick(card.modelData)
                    }
                }
            }
        }
    }
}
