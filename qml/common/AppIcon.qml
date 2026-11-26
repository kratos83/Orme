// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// Un'icona dell'app, presa da assets/icons/ (vedi scripts/fetch_icons.py):
//   AppIcon { name: "rabbit";  size: 96 }   // figura 3D
//   AppIcon { name: "ui/play"; size: 56 }   // simbolo di un pulsante
//
// Per non sprecare RAM l'immagine viene decodificata solo alla risoluzione
// che serve davvero, arrotondata a tre scaglioni (64 / 128 / 256 px): una
// figura piccola occupa 16 KB invece di 256 KB, e tutte le copie della stessa
// figura allo stesso scaglione condividono la stessa memoria (cache di Qt).
Image {
    property string name: ""
    property real size: 64      // lato in px logici

    readonly property real _wanted: size * Screen.devicePixelRatio
    readonly property int _bucket: _wanted <= 72 ? 64 : _wanted <= 144 ? 128 : 256

    width: size
    height: size
    source: name === "" ? "" : "qrc:/qt/qml/Orme/assets/icons/" + name + ".png"
    sourceSize: Qt.size(_bucket, _bucket)
    fillMode: Image.PreserveAspectFit
    smooth: true
}
