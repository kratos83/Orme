import QtQuick
import Orme

// Festa quando il bambino vince un livello: coriandoli, "BRAVO/A!",
// le faccine guadagnate e un messaggio ("Sei al livello N").
Item {
    id: root
    anchors.fill: parent
    visible: false

    signal finished()   // emesso quando la festa e' finita (per andare avanti)

    property int stars: 0
    property string message: ""

    function celebrate(starCount, msg) {
        stars = starCount || 0
        message = msg || ""
        visible = true
        label.scale = 0
        popIn.start()
        hideTimer.restart()
    }

    Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.06 }

    Repeater {
        model: 30
        Rectangle {
            width: 16; height: 16
            radius: 3
            color: ["#EF5350", "#42A5F5", "#FFA726", "#66BB6A", "#AB47BC", "#FFEE58"][index % 6]
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

    Column {
        anchors.centerIn: parent
        spacing: 14

        Text {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            text: "🎉  BRAVO/A!  🎉"
            font.pixelSize: 66
            font.bold: true
            color: Theme.accentDark
            scale: 0
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            Repeater {
                model: root.stars
                Text {
                    id: sm
                    text: "😊"
                    font.pixelSize: 58
                    scale: 0
                    SequentialAnimation {
                        running: root.visible
                        PauseAnimation { duration: 260 + index * 200 }
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
            color: Theme.text
        }
    }

    NumberAnimation {
        id: popIn
        target: label
        property: "scale"
        from: 0; to: 1
        duration: 380
        easing.type: Easing.OutBack
    }

    Timer {
        id: hideTimer
        interval: 2600
        onTriggered: { root.visible = false; root.finished() }
    }
}
