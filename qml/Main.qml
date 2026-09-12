// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import Giochi

Window {
    id: root
    width: Screen.width
    height: Screen.height
    visible: true
    visibility: Window.Maximized
    title: qsTr("Orme")
    color: Theme.background

    // Loader che ospita a turno il menu o un gioco. Ogni gioco emette
    // exitRequested per tornare al menu; uscendo viene distrutto, quindi
    // nome e punteggio ripartono da zero.
    Loader {
        id: view
        anchors.fill: parent
        sourceComponent: launcherComponent
    }

    function openGame(id) {
        var map = {
            "path": pathC, "loop": loopC, "rhythm": rhythmC, "sort": sortC,
            "sequence": sequenceC, "draw": drawC, "catch": catchC, "count": countC,
            "color": colorC, "odd": oddC, "pairs": pairsC, "size": sizeC,
            "bubbles": bubblesC, "dots": dotsC, "wake": wakeC, "cups": cupsC,
            "puzzle": puzzleC, "harvest": harvestC, "balloons": balloonsC, "reveal": revealC,
            "emotions": emotionsC, "recycle": recycleC
        }
        if (map[id]) view.sourceComponent = map[id]
    }

    Component {
        id: launcherComponent
        Launcher {
            onGameSelected: (game) => root.openGame(game)
            onInfoRequested: view.sourceComponent = infoComponent
        }
    }

    Component {
        id: infoComponent
        InfoPage {
            onExitRequested: view.sourceComponent = launcherComponent
            onGameSelected: (id) => root.openGame(id)
        }
    }

    Component { id: pathC;     PathGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: loopC;     LoopGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: rhythmC;   RhythmGame   { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: sortC;     SortGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: sequenceC; SequenceGame { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: drawC;     DrawGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: catchC;    CatchGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: countC;    CountGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: colorC;    ColorGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: oddC;      OddGame      { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: pairsC;    PairsGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: sizeC;     SizeGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: bubblesC;  BubblesGame  { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: dotsC;     DotsGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: wakeC;     WakeGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: cupsC;     CupsGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: puzzleC;   PuzzleGame   { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: harvestC;  HarvestGame  { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: balloonsC; BalloonsGame { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: revealC;   RevealGame   { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: emotionsC; EmotionsGame { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: recycleC;  RecycleGame  { onExitRequested: view.sourceComponent = launcherComponent } }
}
