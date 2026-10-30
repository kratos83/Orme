// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Barra in alto che avvisa quando Updater (src/updater.cpp) trova una
// versione più nuova su GitHub Releases. Non blocca il gioco: si può
// chiudere con "più tardi" e ricompare al prossimo avvio dell'app.
Item {
    id: root
    property bool dismissed: false
    visible: Updater.updateAvailable && !dismissed
    height: 74
    z: 1000

    Rectangle {
        anchors.fill: parent
        color: Theme.panel
        border.color: Theme.accent
        border.width: 2
    }

    Text {
        id: msg
        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter; right: actionRow.left; rightMargin: 16 }
        wrapMode: Text.WordWrap
        text: qsTr("È disponibile Orme %1!").arg(Updater.latestVersion)
        font.pixelSize: 18
        font.bold: true
        color: Theme.text
    }

    Rectangle {   // barra di progresso, visibile solo durante lo scaricamento
        visible: Updater.downloading
        anchors { left: msg.left; right: msg.right; bottom: parent.bottom; bottomMargin: 6 }
        height: 6
        radius: 3
        color: Theme.boardFill
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width * Updater.downloadProgress
            radius: 3
            color: Theme.accent
            Behavior on width { NumberAnimation { duration: 150 } }
        }
    }

    Row {
        id: actionRow
        anchors { right: dismissBtn.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 10

        Rectangle {
            width: actionText.implicitWidth + 32; height: 48; radius: 14
            color: Theme.accent
            opacity: Updater.downloading ? 0.6 : 1
            scale: actionMa.pressed ? 0.95 : 1
            Behavior on scale { NumberAnimation { duration: 80 } }
            Text {
                id: actionText
                anchors.centerIn: parent
                text: Updater.downloading
                      ? qsTr("Scaricamento...")
                      : (Updater.canAutoInstall ? qsTr("Aggiorna ora") : qsTr("Apri pagina download"))
                font.pixelSize: 16
                font.bold: true
                color: "white"
            }
            MouseArea {
                id: actionMa
                anchors.fill: parent
                enabled: !Updater.downloading
                onClicked: {
                    if (Updater.canAutoInstall) Updater.startUpdate()
                    else Qt.openUrlExternally(Updater.releaseUrl)
                }
            }
        }
    }

    Rectangle {   // "più tardi": chiude la barra per questa sessione
        id: dismissBtn
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        width: 44; height: 44; radius: 22
        color: Theme.background
        border.color: Theme.boardLine
        border.width: 2
        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 18; color: Theme.text }
        MouseArea { anchors.fill: parent; onClicked: root.dismissed = true }
    }
}
