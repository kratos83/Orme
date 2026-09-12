import QtQuick
import QtMultimedia

// Raccolta dei 4 effetti sonori, con nomi comodi per i giochi.
//   tap()  -> tocco / selezione
//   ok()   -> risposta giusta / pezzo al posto
//   win()  -> vittoria
//   nope() -> risposta sbagliata
Item {
    id: root
    property string base: "qrc:/qt/qml/Giochi/assets/sounds/"

    function tap()  { sTap.play() }
    function ok()   { sStep.play() }
    function win()  { sWin.play() }
    function nope() { sBump.play() }

    SoundEffect { id: sTap;  source: root.base + "tap.wav" }
    SoundEffect { id: sStep; source: root.base + "step.wav" }
    SoundEffect { id: sWin;  source: root.base + "win.wav" }
    SoundEffect { id: sBump; source: root.base + "bump.wav" }
}
