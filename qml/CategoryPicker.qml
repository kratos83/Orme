// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Schermata iniziale: scegli "Infanzia" o "Primaria", poi si entra nella
// griglia dei giochi di quella sola categoria (Launcher.category).
Item {
    id: root
    signal categorySelected(string category)
    signal quitRequested()

    // lato dei due grandi riquadri, adattato alla finestra
    readonly property real side: Math.max(180, Math.min(320, (width - 120) / 2, height - 300))

    Scenery { theme: "prato" }

    CandyButton {   // Esci, in alto a destra
        anchors { top: parent.top; right: parent.right; margins: 18 }
        height: 62
        text: qsTr("Esci")
        icon: "door"
        textSize: 26
        color: Theme.danger
        onClicked: root.quitRequested()   // prima chiede conferma
    }

    Row {   // il nome dell'app, una lettera per colore, che saltella
        id: logo
        anchors { top: parent.top; topMargin: 20; horizontalCenter: parent.horizontalCenter }
        spacing: 2
        Repeater {
            model: qsTr("Orme").split("")
            Text {
                id: letter
                required property string modelData
                required property int index
                text: modelData
                font.pixelSize: 88
                font.bold: true
                color: Theme.playColors[[0, 1, 5, 3, 4][index % 5]]
                style: Text.Outline
                styleColor: "white"
                property real hop: 0
                transform: Translate { y: letter.hop }
                SequentialAnimation on hop {
                    running: true
                    loops: Animation.Infinite
                    PauseAnimation { duration: letter.index * 160 }
                    NumberAnimation { to: -14; duration: 260; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 0; duration: 420; easing.type: Easing.OutBounce }
                    PauseAnimation { duration: 2600 - letter.index * 160 }
                }
            }
        }
    }

    TitlePill {
        anchors { top: logo.bottom; topMargin: 4; horizontalCenter: parent.horizontalCenter }
        title: qsTr("Per chi sono i giochi oggi?")
        titleSize: 28
    }

    component CategoryCard: Rectangle {
        id: cat
        property string title: ""
        property string age: ""
        property string icon: ""
        property color baseColor: Theme.dirRight
        signal clicked()

        width: root.side; height: root.side; radius: 48
        color: baseColor
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(cat.baseColor, 1.25) }
            GradientStop { position: 0.7; color: cat.baseColor }
        }
        border.color: "white"
        border.width: 6
        scale: ma.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

        Candy { depth: 10 }

        Column {
            anchors.centerIn: parent
            spacing: 6
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: cat.width * 0.55; height: width; radius: width / 2
                color: "#F5FFFFFF"
                AppIcon {
                    anchors.centerIn: parent
                    name: cat.icon
                    size: parent.width * 0.8
                    SequentialAnimation on scale {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.1; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: cat.title
                font.pixelSize: cat.width * 0.13
                font.bold: true
                color: "white"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: cat.age
                font.pixelSize: cat.width * 0.07
                font.bold: true
                color: "white"
            }
        }
        MouseArea { id: ma; anchors.fill: parent; onClicked: cat.clicked() }
    }

    Row {
        anchors { centerIn: parent; verticalCenterOffset: 50 }
        spacing: 48

        CategoryCard {
            title: qsTr("Infanzia")
            age: qsTr("3-5 anni")
            icon: "teddy"
            baseColor: Theme.dirLeft
            onClicked: root.categorySelected("infanzia")
        }
        CategoryCard {
            title: qsTr("Primaria")
            age: qsTr("6-10 anni")
            icon: "backpack"
            baseColor: Theme.dirUp
            onClicked: root.categorySelected("primaria")
        }
    }

    Rectangle {
        anchors.centerIn: footer
        width: Math.min(footer.width, footer.implicitWidth + 36)
        height: footer.height + 8
        radius: height / 2
        color: "#E6FFFFFF"
    }

    Text {
        id: footer
        width: parent.width - 40
        anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        textFormat: Text.RichText
        text: "© 2026 Angelo Scarnà - software libero (GPLv3). Per info contattare: " +
              "<a href=\"mailto:angelo.scarna@primanotanet.it\">angelo.scarna@primanotanet.it</a>"
        linkColor: Theme.accentDark
        font.pixelSize: 15
        color: Theme.text
        onLinkActivated: (link) => Qt.openUrlExternally(link)
    }
}
