import QtQuick
import Orme

// Festa quando il bambino vince un livello: raggi di sole, coriandoli,
// "BRAVO/A!", le stelle guadagnate e un messaggio ("Sei al livello N").
Item {
    id: root
    anchors.fill: parent
    visible: false

    signal finished()   // emesso quando la festa e' finita (per andare avanti)

    property int stars: 0
    property string message: ""

    readonly property var colors: ["#EF5350", "#42A5F5", "#FFA726", "#66BB6A", "#AB47BC", "#FFCA28"]

    function celebrate(starCount, msg) {
        stars = starCount || 0
        message = msg || ""
        visible = true
        card.scale = 0
        popIn.start()
        hideTimer.restart()
    }

    Rectangle { anchors.fill: parent; color: "#994A2C7A" }

    Item {   // raggi che girano dietro la scheda
        anchors.centerIn: parent
        NumberAnimation on rotation {
            running: root.visible
            from: 0; to: 360
            duration: 14000
            loops: Animation.Infinite
        }
        Repeater {
            model: 12
            Item {
                required property int index
                rotation: index * 30
                Rectangle {
                    x: -34
                    y: -Math.max(root.width, root.height) * 0.55
                    width: 68
                    height: -y
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00FFE082" }
                        GradientStop { position: 1.0; color: "#C0FFE082" }
                    }
                }
            }
        }
    }

    Repeater {   // coriandoli: quadratini e pallini colorati
        model: 36
        Rectangle {
            required property int index
            width: index % 3 === 0 ? 12 : 18
            height: index % 3 === 0 ? 22 : 18
            radius: index % 3 === 1 ? 9 : 4
            color: root.colors[index % root.colors.length]
            x: Math.random() * root.width
            visible: root.visible

            NumberAnimation on y {
                running: root.visible
                from: -30
                to: root.height + 40
                duration: 1500 + Math.random() * 1400
                loops: Animation.Infinite
            }
            RotationAnimation on rotation {
                running: root.visible
                from: 0; to: 360
                duration: 900 + Math.random() * 900
                loops: Animation.Infinite
            }
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(root.width - 40, Math.max(560, content.implicitWidth + 80))
        height: content.implicitHeight + 60
        radius: 48
        color: "white"
        border.color: "#FFCA28"
        border.width: 8
        scale: 0

        Candy { depth: 10 }

        Column {
            id: content
            anchors.centerIn: parent
            spacing: 16

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18

                AppIcon { name: "party"; size: 80; anchors.verticalCenter: parent.verticalCenter }
                Row {   // ogni lettera di un colore diverso
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: "BRAVO/A!".split("")
                        Text {
                            required property string modelData
                            required property int index
                            text: modelData
                            font.pixelSize: 68
                            font.bold: true
                            color: root.colors[index % 5]
                        }
                    }
                }
                AppIcon { name: "party"; size: 80; mirror: true; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                visible: root.stars > 0
                Repeater {
                    model: root.stars
                    AppIcon {
                        id: sm
                        required property int index
                        name: "star-glowing"
                        // la stella di mezzo e' piu' grande
                        size: root.stars === 3 && index === 1 ? 132 : 100
                        scale: 0
                        SequentialAnimation {
                            running: root.visible
                            PauseAnimation { duration: 260 + sm.index * 200 }
                            NumberAnimation { target: sm; property: "scale"; from: 0; to: 1.25; duration: 160; easing.type: Easing.OutBack }
                            NumberAnimation { target: sm; property: "scale"; to: 1.0; duration: 120 }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.message !== ""
                text: root.message
                font.pixelSize: 34
                font.bold: true
                color: Theme.title
            }
        }
    }

    NumberAnimation {
        id: popIn
        target: card
        property: "scale"
        from: 0; to: 1
        duration: 420
        easing.type: Easing.OutBack
    }

    Timer {
        id: hideTimer
        interval: 2600
        onTriggered: { root.visible = false; root.finished() }
    }
}
