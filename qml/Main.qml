// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import Orme

Window {
    id: root
    width: Screen.width
    height: Screen.height
    visible: true
    visibility: Window.Maximized
    title: qsTr("Orme")
    color: Theme.background

    onClosing: function(close) {
        close.accepted = false
        quitDialog.active = true
    }
    // Loader che ospita a turno il menu o un gioco. Ogni gioco emette
    // exitRequested per tornare al menu; uscendo viene distrutto, quindi
    // nome e punteggio ripartono da zero.
    Loader {
        id: view
        anchors.fill: parent
        sourceComponent: categoryComponent
    }

    // Avviso di aggiornamento disponibile, sopra a tutto il resto; non
    // blocca il gioco, si può chiudere con "più tardi" (vedi UpdateBanner.qml).
    UpdateBanner {
        anchors { top: parent.top; left: parent.left; right: parent.right }
    }

    // Conferma di uscita: sta sopra a tutto, cosi' annullando si ritrova la
    // schermata (o la partita) com'era.
    Loader {
        id: quitDialog
        anchors.fill: parent
        z: 2000
        active: false
        sourceComponent: Component { Esci { onExitRequested: quitDialog.active = false } }
    }

    // Controllo silenzioso all'avvio: fallisce senza avvisi se non c'è rete.
    Timer { interval: 2000; running: true; onTriggered: Updater.checkForUpdates() }

    property string currentCategory: "infanzia"

    function openGame(id) {
        var map = {
            "path": pathC, "loop": loopC, "rhythm": rhythmC, "sort": sortC,
            "sequence": sequenceC, "draw": drawC, "catch": catchC, "count": countC,
            "color": colorC, "odd": oddC, "pairs": pairsC, "size": sizeC,
            "bubbles": bubblesC, "dots": dotsC, "wake": wakeC, "cups": cupsC,
            "puzzle": puzzleC, "trainpuzzle": trainPuzzleC, "harvest": harvestC, "balloons": balloonsC, "reveal": revealC,
            "emotions": emotionsC, "recycle": recycleC, "shapes": shapesC, "snake": snakeC,
            "stopgo": stopgoC, "poses": posesC, "kitchen": kitchenC, "tower": towerC, "beans": beansC, "train": trainC,
            "voweltrain": vowelTrainC, "numbertrain": numberTrainC,
            "line20": line20C, "add": addC, "sub": subC, "mul": mulC, "div": divC,
            "fractions": fractionsC, "tables": tablesC, "numberline": numberlineC,
            "regions": regionsC,
            "syllables": syllablesC, "doubles": doublesC, "spelling": spellingC,
            "lettercount": lettercountC, "guessword": guesswordC, "reorder": reorderC,
            "subjectverb": subjectverbC, "pronouns": pronounsC, "alphabet": alphabetC
        }
        if (map[id]) view.sourceComponent = map[id]
    }

    Component {
        id: categoryComponent
        CategoryPicker {
            onQuitRequested: quitDialog.active = true
            onCategorySelected: (cat) => {
                root.currentCategory = cat
                view.sourceComponent = launcherComponent
            }
        }
    }

    Component {
        id: launcherComponent
        Launcher {
            category: root.currentCategory
            onQuitRequested: quitDialog.active = true
            onGameSelected: (game) => root.openGame(game)
            onInfoRequested: view.sourceComponent = infoComponent
            onBackRequested: view.sourceComponent = categoryComponent
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
    Component { id: trainPuzzleC; JigsawGame   { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: harvestC;  HarvestGame  { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: balloonsC; BalloonsGame { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: revealC;   RevealGame   { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: emotionsC; EmotionsGame { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: recycleC;  RecycleGame  { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: shapesC;   ShapesGame   { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: snakeC;    SnakeGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: stopgoC;   StopGoGame   { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: posesC;    PosesGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: kitchenC;  KitchenGame  { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: towerC;    TowerGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: beansC;    BeansGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: trainC;    TrainGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: vowelTrainC;  VowelTrainGame  { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: numberTrainC; NumberTrainGame { onExitRequested: view.sourceComponent = launcherComponent } }

    Component { id: line20C;     Line20Game     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: addC;        ArithmeticGame { opMode: "add"; onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: subC;        ArithmeticGame { opMode: "sub"; onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: mulC;        ArithmeticGame { opMode: "mul"; onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: divC;        ArithmeticGame { opMode: "div"; onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: fractionsC;  FractionsGame  { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: tablesC;     TablesGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: numberlineC; NumberLineGame { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: regionsC;    RegionsGame    { onExitRequested: view.sourceComponent = launcherComponent } }

    Component { id: syllablesC;   SyllablesGame   { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: doublesC;     DoublesGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: spellingC;    SpellingGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: lettercountC; LetterCountGame { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: guesswordC;   GuessWordGame   { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: reorderC;     ReorderGame     { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: subjectverbC; SubjectVerbGame { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: pronounsC;    PronounsGame    { onExitRequested: view.sourceComponent = launcherComponent } }
    Component { id: alphabetC;    AlphabetGame    { onExitRequested: view.sourceComponent = launcherComponent } }
}
