// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// Estende GameScaffold con il "giro" standard di un mini-gioco:
//   - livello corrente (levelIndex) su un totale (levelCount)
//   - conteggio errori (mistakes) -> faccine 1..3
//   - vittoria con festa + messaggio + passaggio automatico al livello dopo
//
// Un gioco su MiniGame deve solo:
//   onBuildLevel: (i) => load(i)      // costruisce il livello i
//   ... e chiamare  win()  quando è finito,  wrong()  a ogni errore.
GameScaffold {
    id: mg

    property int  levelIndex: 0
    property int  levelCount: 1
    property int  mistakes: 0
    property bool won: false

    showNext: won

    signal buildLevel(int index)

    onRestartRequested: mg.buildLevel(levelIndex)
    onNextRequested: _advance()
    onWinFinished: _advance()

    function _advance() {
        if (!won) return
        mg.buildLevel((levelIndex + 1) % Math.max(1, levelCount))
    }

    function win() {
        won = true
        reward(3 - Math.min(2, mistakes),
               qsTr("Sei al livello ") + (((levelIndex + 1) % Math.max(1, levelCount)) + 1))
    }

    function wrong() { mistakes += 1 }

    Component.onCompleted: mg.buildLevel(levelIndex)
}
