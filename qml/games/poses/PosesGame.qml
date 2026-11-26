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

    readonly property var poses: ["frog", "lion", "eagle", "bear", "superhero", "ninja", "gymnast", "dancer"]

    property string command: "frog"
    property var choices: ["frog", "lion", "eagle"]

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
            Candy {}
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 12 }
            width: 190; height: 190
            radius: 32
            color: Theme.panel
            border.color: Theme.accent
            border.width: 5
            AppIcon { anchors.centerIn: parent; name: g.command; size: 138 }
        }

        AppIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            y: commandCard.y + commandCard.height + 10
            name: "ui/down"
            size: 42
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
                    Candy {}
                    width: 150; height: 150
                    radius: 26
                    color: Theme.panel
                    border.color: Theme.boardLine
                    border.width: 3

                    required property string modelData

                    scale: cardMa.pressed && !g.won ? 0.93 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    AppIcon { anchors.centerIn: parent; name: card.modelData; size: 103 }

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
