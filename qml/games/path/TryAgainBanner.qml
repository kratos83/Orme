import QtQuick
import Giochi

// Messaggio "hai sbagliato, riprova" quando la sequenza e' sbagliata.
// Compare per un attimo e sparisce da solo mentre i comandi si azzerano.
Item {
    id: root
    anchors.fill: parent
    visible: false

    function show() {
        visible = true
        card.scale = 0
        pop.restart()
        hideTimer.restart()
    }

    Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.06 }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(root.width * 0.72, 560)
        height: 200
        radius: 32
        color: Theme.panel
        border.color: Theme.danger
        border.width: 5
        scale: 0

        Row {
            anchors.centerIn: parent
            spacing: 24

            Text {
                text: "🙈"
                font.pixelSize: 84
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: qsTr("Ops! Riprova")
                font.pixelSize: 46
                font.bold: true
                color: Theme.danger
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    NumberAnimation {
        id: pop
        target: card
        property: "scale"
        from: 0; to: 1
        duration: 320
        easing.type: Easing.OutBack
    }

    Timer {
        id: hideTimer
        interval: 1250
        onTriggered: root.visible = false
    }
}
