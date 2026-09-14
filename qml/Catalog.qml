pragma Singleton
import QtQuick
import Orme

// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
// Elenco dei 20 giochi, usato dal menu (Launcher) e dalla pagina Info.
// Campi: id, title, age, c (colore), e (emoji) o icon ("path"), desc.
QtObject {
    readonly property var games: [
        { id: "path", title: qsTr("Il percorso"), age: qsTr("3-5 anni"), c: Theme.dirUp, icon: "path",
          desc: qsTr("Componi la fila di frecce; il robot le esegue un passo alla volta fino all'oggetto. Sequenza / algoritmo, e correggere e riprovare.") },
        { id: "loop", title: qsTr("Ancora!"), age: qsTr("4-5 anni"), c: Theme.dirDown, e: "🐸",
          desc: qsTr("Scegli quante volte ripetere il salto: il coniglio deve arrivare esatto sulla carota. Il ciclo / ripetizione.") },
        { id: "rhythm", title: qsTr("Il ritmo"), age: qsTr("3-5 anni"), c: Theme.dirRight, e: "🔴🔵",
          desc: qsTr("Una fila di pallini colorati che segue un ritmo e finisce con '?'. Tocca quello che continua il ritmo. I pattern.") },
        { id: "sort", title: qsTr("Metti a posto"), age: qsTr("3-4 anni"), c: Theme.dirLeft, e: "📦",
          desc: qsTr("Trascina l'oggetto nel cesto giusto: per colore, per grandezza, per tipo. Classificare / condizione 'se... allora...'.") },
        { id: "sequence", title: qsTr("E poi?"), age: qsTr("4-5 anni"), c: Theme.accent, e: "👣",
          desc: qsTr("Figure mescolate in alto, caselle 1-2-3 in basso: tocca le figure nell'ordine giusto (seme, germoglio, albero...).") },
        { id: "draw", title: qsTr("Disegna il percorso"), age: qsTr("3-5 anni"), c: Theme.dirRight, e: "✏️",
          desc: qsTr("Col dito disegni una strada dal personaggio fino all'oggetto (fiore, pupazzo, palla...); poi lui la percorre.") },
        { id: "catch", title: qsTr("Acchiappa i conigli"), age: qsTr("3-5 anni"), c: Theme.dirDown, e: "🐰",
          desc: qsTr("Fra gli animali che ondeggiano tocca solo i conigli. Toccare un altro animale è un errore.") },
        { id: "count", title: qsTr("Conta"), age: qsTr("4-5 anni"), c: Theme.dirUp, e: "🔢",
          desc: qsTr("Quanti animali ci sono? Tocca il numero giusto, da 1 a 5.") },
        { id: "color", title: qsTr("Tocca il colore"), age: qsTr("3-4 anni"), c: Theme.dirLeft, e: "🎨",
          desc: qsTr("In alto una macchia di colore, sotto quattro cerchi: tocca quello dello stesso colore.") },
        { id: "odd", title: qsTr("Trova l'intruso"), age: qsTr("3-5 anni"), c: Theme.accent, e: "🔍",
          desc: qsTr("Quattro figure, tre uguali e una diversa: tocca quella diversa. Il confronto.") },
        { id: "pairs", title: qsTr("Le coppie"), age: qsTr("4-5 anni"), c: Theme.dirUp, e: "🃏",
          desc: qsTr("Memory con 6 carte (3 coppie): giri due carte, se sono uguali restano su.") },
        { id: "size", title: qsTr("Il più grande"), age: qsTr("3-4 anni"), c: Theme.dirDown, e: "🐘",
          desc: qsTr("Due o tre figure uguali di misura diversa: tocca la più grande.") },
        { id: "bubbles", title: qsTr("Bolle"), age: qsTr("3-5 anni"), c: Theme.dirRight, e: "🔵",
          desc: qsTr("Le bolle colorate salgono piano: toccale per farle scoppiare. Toccane abbastanza per vincere.") },
        { id: "dots", title: qsTr("Unisci i puntini"), age: qsTr("4-5 anni"), c: Theme.dirLeft, e: "⭐",
          desc: qsTr("Tocca i puntini in ordine da 1 a 5: a ogni tocco giusto si disegna un pezzo di linea.") },
        { id: "wake", title: qsTr("Sveglia gli animali"), age: qsTr("3-4 anni"), c: Theme.accent, e: "😴",
          desc: qsTr("Sei animali dormono: toccali tutti per svegliarli, ognuno fa un saltino.") },
        { id: "cups", title: qsTr("Dov'è il coniglio?"), age: qsTr("4-5 anni"), c: Theme.dirUp, e: "❓",
          desc: qsTr("Il coniglio si nasconde sotto un bicchiere; i bicchieri si mescolano, poi tocca quello giusto.") },
        { id: "puzzle", title: qsTr("Puzzle"), age: qsTr("3-5 anni"), c: Theme.dirDown, e: "🧩",
          desc: qsTr("Quattro pezzi da trascinare nella cornice 2x2; ogni casella mostra in trasparenza il pezzo che ci va.") },
        { id: "harvest", title: qsTr("Raccogli i frutti"), age: qsTr("3-5 anni"), c: Theme.dirRight, e: "🍎",
          desc: qsTr("I frutti colorati scendono piano dall'alto: toccali per metterli nel cesto.") },
        { id: "balloons", title: qsTr("Palloncini in fila"), age: qsTr("3-5 anni"), c: Theme.dirLeft, e: "🎈",
          desc: qsTr("Tocca i palloncini dal più piccolo al più grande. Mettere in ordine per grandezza.") },
        { id: "reveal", title: qsTr("Scopri chi è"), age: qsTr("3-4 anni"), c: Theme.accent, e: "🐱",
          desc: qsTr("Dietro le mattonelle colorate c'è un animale: toccale tutte per scoprirlo.") },
        { id: "emotions", title: qsTr("Le emozioni"), age: qsTr("3-4 anni"), c: Theme.dirDown, e: "😀",
          desc: qsTr("In alto una faccia con un'emozione, sotto quattro facce diverse: tocca quella con la stessa emozione.") },
        { id: "recycle", title: qsTr("La raccolta differenziata"), age: qsTr("3-5 anni"), c: Theme.dirRight, e: "♻️",
          desc: qsTr("Trascina l'oggetto nel bidone giusto: plastica, carta o vetro.") },
        { id: "shapes", title: qsTr("Il percorso delle forme"), age: qsTr("3-5 anni"), c: Theme.dirLeft, e: "🔺",
          desc: qsTr("Sagome colorate sul pavimento in 5 file: in alto una forma o un colore indica la regola, tocca solo quelle giuste per attraversare l'aula.") },
        { id: "snake", title: qsTr("Il serpente"), age: qsTr("4-5 anni"), c: Theme.accent, e: "🐍",
          desc: qsTr("Muovi il serpente con le frecce, una casella alla volta: mangia le mele e cresci, senza toccare i muri o il tuo stesso corpo.") }
    ]
}
