## Novità
Raccolta di 26 giochi touch per bambini di 3-5 anni, ispirati ai concetti del
coding. 

Linguagio utilizzato: Qt 6 + C++ + QML.

**26 giochi**, tutti nel menu iniziale: griglia che si adatta alla larghezza
(3-6 riquadri per riga) e scorre in verticale; il titolo lungo va a capo.
L'età consigliata è scritta su ogni riquadro e nell'intestazione del gioco
(proprietà `age`).

Aggiunti quattro nuovi giochi:
- **Le emozioni** - tocca la faccia con la stessa emozione di quella mostrata.
- **La raccolta differenziata** - trascina l'oggetto nel bidone giusto
  (plastica, carta o vetro).
- **Il percorso delle forme** - una forma o un colore indica la regola: salta
  di fila in fila toccando solo la sagoma giusta, fino ad attraversare l'aula.
- **Il serpente** - guida con le frecce (o toccando il campo) il serpente che
  avanza da solo: mangia le mele e cresci, senza toccare i muri o te stesso.


## Bug risolti

- Risolto bug bundle macos
- Risolto bug icon non caricate su Android
- Risolte le icone (emoji) del menu e dei giochi non visibili su telefoni e
  tablet Android reali privi di font emoji a colori di sistema: l'app ora
  include un proprio font emoji (Noto Color Emoji) usato automaticamente
  come fallback
- Risolte le stesse icone (emoji) non visibili anche su Windows: il
  rendering del testo è forzato sul percorso "nativo", l'unico che
  garantisce i glyph a colori su tutte le piattaforme

## I pacchetti sono disponibili:

- Android
- Linux (**Fedora - Mageia - Arch linux - Alpine - Debian - Opensuse**)
- Windows (**Portabile - Installazione fissa**)
- MacOS (**Versione universale -Intel-Processore serie M**)