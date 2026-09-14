# Orme

Raccolta di 24 giochi touch per bambini di 3-5 anni, ispirati ai concetti del
coding. 

Linguagio utilizzato: Qt 6 + C++ + QML.

Link al sito: <https://codelinsoft.it/orme>

© 2026 Angelo Scarnà — vedi [COPYRIGHT](COPYRIGHT).

## Requisiti

- Qt 6.5 o superiore (`qt6-base-dev`, `qt6-declarative-dev`)
- Modulo QML `QtMultimedia` a runtime (`qml6-module-qtmultimedia`) per i suoni
- CMake 3.21+
- Python 3 (solo per rigenerare gli effetti sonori)

## Compilare ed eseguire

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
./build/Orme
```

Per ripulire i file di compilazione: `scripts/clean.sh` elimina `build/` e
tutti gli artefatti generati da CMake/Qt (anche quelli di una build in-source
finiti nella radice). `scripts/clean.sh --all` toglie pure altre cartelle di
build (`build-*`, `cmake-build-*`, ...).

## Pacchetti per altre piattaforme

Debian/Ubuntu, Fedora, openSUSE, Mageia, Arch, Alpine, Android, Windows e
macOS: vedi [packaging/README.md](packaging/README.md).

## I giochi

**24 giochi**, tutti nel menu iniziale: griglia che si adatta alla larghezza
(3-6 riquadri per riga) e scorre in verticale; il titolo lungo va a capo.
L'età consigliata è scritta su ogni riquadro e nell'intestazione del gioco
(proprietà `age`). Le icone (menu e giochi) sono emoji; per non dipendere dal
font emoji di sistema - assente su molti tablet Android reali, specie senza
servizi Google, con il risultato di icone invisibili o "quadratini vuoti" -
l'app include Noto Color Emoji (`assets/fonts/NotoColorEmoji.ttf`, licenza
OFL) e lo imposta come fallback del font di default all'avvio
(`src/main.cpp`), cosi' le emoji si vedono uguali su ogni dispositivo.

| # | Riquadro | Età | Cartella | Idea |
|---|---|---|---|---|
| 1 | **Il percorso** | 3-5 | `games/path/` | sequenza / algoritmo, passo-passo, debug (motore C++) |
| 2 | **Ancora!** | 4-5 | `games/loop/` | ciclo: fai il salto **N volte** |
| 3 | **Il ritmo** | 3-5 | `games/rhythm/` | pattern che si ripete |
| 4 | **Metti a posto** | 3-4 | `games/sort/` | classificare / "se... allora..." (drag) |
| 5 | **E poi?** | 4-5 | `games/sequence/` | mettere i passi in ordine |
| 6 | **Disegna il percorso** | 3-5 | `games/draw/` | col dito disegni la strada, il personaggio va all'oggetto |
| 7 | **Acchiappa i conigli** | 3-5 | `games/catch/` | tocca solo i 🐰 (condizione), non gli altri animali |
| 8 | **Conta** | 4-5 | `games/count/` | quanti animali? tocca il numero |
| 9 | **Tocca il colore** | 3-4 | `games/color/` | tocca il cerchio del colore mostrato |
| 10 | **Trova l'intruso** | 3-5 | `games/odd/` | 3 uguali + 1 diverso: tocca il diverso |
| 11 | **Le coppie** | 4-5 | `games/pairs/` | memory con 3 coppie |
| 12 | **Il più grande** | 3-4 | `games/size/` | tocca la figura più grande |
| 13 | **Bolle** | 3-5 | `games/bubbles/` | scoppia le bolle che salgono |
| 14 | **Unisci i puntini** | 4-5 | `games/dots/` | tocca i puntini in ordine da 1 a 5 |
| 15 | **Sveglia gli animali** | 3-4 | `games/wake/` | tocca ogni animale che dorme |
| 16 | **Dov'è il coniglio?** | 4-5 | `games/cups/` | segui il bicchiere dopo uno scambio |
| 17 | **Puzzle** | 3-5 | `games/puzzle/` | trascina 4 pezzi nella cornice 2x2 |
| 18 | **Raccogli i frutti** | 3-5 | `games/harvest/` | tocca i frutti che cadono |
| 19 | **Palloncini in fila** | 3-5 | `games/balloons/` | tocca i palloncini dal più piccolo al più grande |
| 20 | **Scopri chi è** | 3-4 | `games/reveal/` | togli le mattonelle e scopri l'animale |
| 21 | **Le emozioni** | 3-4 | `games/emotions/` | tocca la faccia con la stessa emozione |
| 22 | **La raccolta differenziata** | 3-5 | `games/recycle/` | trascina l'oggetto nel bidone giusto (plastica/carta/vetro) |
| 23 | **Il percorso delle forme** | 3-5 | `games/shapes/` | salta di fila in fila sulla sagoma giusta (forma o colore indicato) |
| 24 | **Il serpente** | 4-5 | `games/snake/` | avanza da solo su una griglia, le frecce sterzano, mangia le mele e cresce |

Regole comuni pensate per 3-5 anni: niente testo da leggere (icone + colore +
suono), bersagli touch grandi, nessuna schermata di sconfitta, festa e "Ops!
Riprova" sempre uguali.

**Nome del bambino (in tutti i 24 giochi).** All'ingresso di ogni gioco compare
la schermata "Come ti chiami?" (`NamePrompt.qml`, dentro `GameScaffold` quindi
ereditata anche da `MiniGame` e da tutti i giochi): campo di testo + "Gioca" o
"Salta". Il nome resta scritto nell'intestazione e si può **cambiare in
qualunque momento** col tasto **👤** (accanto a 🔄). Uscendo con ← il gioco
viene distrutto e ricreato, quindi **nome e punteggio si azzerano** per il
bambino successivo.

**Menu Info.** In alto a destra nel menu c'è il tasto **i**: apre `InfoPage.qml`
con la presentazione del programma (scopo, versione, © e email) e **l'elenco di
tutti i 24 giochi** con concetto ed età; toccando una riga si apre quel gioco.
L'elenco dei giochi (id, titolo, età, colore, emoji, descrizione) è il singleton
`Catalog.qml`, usato sia dal menu sia dalla pagina Info.

**Punteggio e passaggio di livello.** Ogni livello vinto dà da 1 a 3 faccine
😊 (3 se nessun errore, poi -1 per errore, minimo 1). Il totale della sessione
è sempre visibile in una targhetta con la faccina. Quando il bambino vince
parte la festa ("BRAVO/A!", le faccine guadagnate, "Sei al livello N") e poi
**si passa da soli al livello successivo**; la grande freccia "avanti" serve
solo a saltare l'attesa. Il conteggio degli errori del livello sta in una
proprietà `mistakes` per gioco; il totale in `GameScaffold.score`
(in "Il percorso" è `PathGame.score`). Componenti: `ScoreBar.qml` per la
targhetta, `Celebration.qml` per festa + faccine + messaggio.

## Struttura

```
CMakeLists.txt        elenca ogni .qml in QML_FILES
COPYRIGHT
src/
  main.cpp            avvio: carica il modulo QML "Orme", pagina Main
  pathengine.{h,cpp}  logica del gioco "Il percorso" (in C++)
qml/
  Main.qml            finestra + Loader; mappa id-gioco -> Component (+ InfoPage)
  Theme.qml           singleton: colori e misure condivise
  Catalog.qml         singleton: elenco dei 24 giochi (id/titolo/età/colore/emoji/desc)
  Launcher.qml        menu scorrevole (griglia 3-6 col.) + tasto "i" -> Info
  InfoPage.qml        presentazione del programma + elenco di tutti i giochi
  GameTile.qml        un riquadro del menu (title, age, emoji/icona)
  common/
    GameScaffold.qml  cornice: nome bambino, sfondo, intestazione
                      (indietro/ricomincia/titolo/età/nome), area di gioco,
                      pulsante "avanti", overlay festa + errore, ScoreBar.
                      Funzioni: reward(faccine,msg), celebrate(), oops()
    MiniGame.qml       estende GameScaffold col giro standard livello+punteggio:
                      levelIndex/levelCount/mistakes/won, segnale buildLevel(i),
                      funzioni win() e wrong(); auto-avanza dopo la festa
    NamePrompt.qml     schermata iniziale "Come ti chiami?"
    SoundBank.qml      i 4 effetti sonori: tap()/ok()/win()/nope()
    ScoreBar.qml       targhetta 😊 + numero
  games/path/          "Il percorso": PathGame + Board, DirectionPad,
                      CommandStrip, Arrow, Character, Goal, Rock,
                      Celebration, TryAgainBanner
  games/loop|rhythm|sort|sequence/   giochi 2-5 (radice GameScaffold)
  games/draw|catch|count|color|odd|pairs|size|bubbles|dots|wake|
        cups|puzzle|harvest|balloons|reveal|emotions|recycle|shapes|
        snake/
                                             giochi 6-24 (radice MiniGame,
                                             tranne recycle che usa GameScaffold)
assets/sounds/         effetti WAV (rigenerabili con scripts/make_sounds.py)
assets/fonts/          font FluentEmojiColor (Windows)-NotoColorEmoji (Linux-MacOS-Android)
scripts/               make_sounds.py, check_levels.py, clean.sh
```

Tutti i file `.qml` del modulo sono referenziabili per nome (`GameScaffold`,
`MiniGame`, `SoundBank`, `Arrow`, ...) grazie a `qt_add_qml_module`: i nomi
devono essere **unici in tutto il progetto**. "Il percorso" ha un motore in
C++ (`PathEngine`), gli altri 23 hanno la logica in QML/JS.

## Il gioco "Il percorso"

Il bambino tocca le frecce (su/giu/sinistra/destra) per comporre una sequenza,
poi preme il tasto verde: il robottino esegue un passo alla volta. Se arriva
sull'oggetto con le frecce appena finite, parte la festa.

E' un errore (compare "Ops! Riprova", la sequenza si azzera da sola e il
personaggio torna alla partenza) in tre casi:

- sbatte contro un muro o una roccia;
- le frecce finiscono senza essere arrivati sull'oggetto;
- ci sono **troppe frecce**: il personaggio arriva sull'oggetto ma avrebbe
  ancora mosse da fare e lo supererebbe.

Nessuna schermata di sconfitta.

**24 livelli.** I primi 14 sono per la scuola dell'infanzia: griglie 3x3 / 4x4,
da 1 a 6 passi, nessun ostacolo. Dal livello 15 in poi crescono: griglie fino a
7x7, rocce da aggirare, percorsi a serpentina (fino a ~24 passi). Ogni livello
ha un **oggetto diverso da raggiungere** (mela, palla, stella, chiave, regalo...),
mostrato come emoji in `Goal.qml`.

I livelli sono definiti in `PathEngine::PathEngine()` in
[src/pathengine.cpp](src/pathengine.cpp): un elenco di
`{colonne, righe, partenza, traguardo, emoji, rocce}`. Per aggiungerne o
modificarli basta toccare quella lista. `python3 scripts/check_levels.py` rifa'
il BFS di ogni livello per verificare che sia risolvibile (tieni la lista dello
script allineata a quella C++).

## Gli altri giochi

- **Ancora!** (`games/loop/LoopGame.qml`) - una sola azione, il salto: il
  bambino sceglie con la manopola **quante volte** ripeterla (1-6) e preme
  "vai". Il coniglio salta quel numero di volte; se arriva esatto sulla carota
  vince, se no "Ops! Riprova" e torna all'inizio. 8 livelli (distanza 2-6).
- **Il ritmo** (`games/rhythm/RhythmGame.qml`) - una fila di pallini colorati
  che segue un ritmo e finisce con "?". Il bambino tocca, fra tre, la pallina
  che continua il ritmo. 10 ritmi (AB, AAB, ABC, ABB, AABB...).
- **Metti a posto** (`games/sort/SortGame.qml`) - trascina l'oggetto al centro
  nel cesto giusto. Quando entra, l'oggetto vola dentro rimpicciolendo e nel
  cesto **si aggiunge una pallina** (compare con un saltino, `Easing.OutBack`)
  mentre il cesto fa un rimbalzo; il conteggio per cesto è in `binCounts`.
  3 turni: per colore (3 cesti), per grandezza (2), per tipo animali/frutta (2).
  6 oggetti a turno.
- **E poi?** (`games/sequence/SequenceGame.qml`) - figure mescolate in alto,
  caselle 1-2-3(-4) in basso: tocca le figure nell'ordine giusto (seme ->
  germoglio -> albero, ...). 8 sequenze, le ultime due da 4 passi.
- **Disegna il percorso** (`games/draw/DrawGame.qml`) - col dito si disegna
  una strada (Shape + PathPolyline); il tracciato deve partire vicino al
  personaggio, poi lui lo percorre e se finisce sull'oggetto (fiore, pupazzo,
  palla...) hai vinto. 8 livelli.
- **Acchiappa i conigli** (`games/catch/CatchGame.qml`) - fra gli animali che
  ondeggiano si toccano solo i 🐰; toccare un altro animale è un errore.
- **Orme "tocca la risposta"** (`count`, `color`, `odd`, `size`) - una
  domanda visiva e alcune scelte; tocco giusto = livello vinto, tocco
  sbagliato = errore + scossa. ~10-12 livelli generati a caso.
- **Le coppie** (`games/pairs/PairsGame.qml`) - memory 3x2: due carte girate,
  se uguali restano su. Le coppie sbagliate contano come errori.
- **Bolle / Raccogli i frutti** (`bubbles`, `harvest`) - bersagli che si
  muovono (Timer per-oggetto, caduta lenta ~1.2-2.6 px/tick); i frutti sono
  emoji su un disco colorato (`Theme.playColors`). Toccane abbastanza per
  vincere, nessun errore possibile (sempre 3 faccine). La velocità di caduta
  è `speed: 1.2 + index * 0.35` in `HarvestGame.qml`.
- **Unisci i puntini** (`games/dots/DotsGame.qml`) - 5 puntini da toccare in
  ordine 1->5, la linea si disegna man mano. 6 disposizioni.
- **Sveglia gli animali** (`games/wake/WakeGame.qml`) - 6 animali che dormono,
  toccali tutti; ognuno fa un saltino.
- **Dov'è il coniglio?** (`games/cups/CupsGame.qml`) - il coniglio sotto un
  bicchiere. Fasi `peek` (bicchieri alzati, si vede il coniglio) →
  `shuffle` (3-6 scambi in fila, `shuffleTimer`; il coniglio è figlio del suo
  bicchiere quindi lo segue) → `guess` (si tocca) → `done`. Il coniglio è
  `visible` solo se `cup.up`, quindi durante la mescolata non si vede.
- **Puzzle** (`games/puzzle/PuzzleGame.qml`) - 4 pezzi da trascinare nella
  cornice 2x2 (drag imperativo come "Metti a posto"). 5 scene.
- **Palloncini in fila** (`games/balloons/BalloonsGame.qml`) - toccare i
  palloncini in ordine di grandezza.
- **Scopri chi è** (`games/reveal/RevealGame.qml`) - una griglia di mattonelle
  colorate; toccarle tutte scopre l'animale dietro.
- **Le emozioni** (`games/emotions/EmotionsGame.qml`) - stessa struttura di
  "Tocca il colore" ma con facce invece di colori: in alto una faccia con
  un'emozione (6 possibili), sotto quattro facce diverse, tocca quella con la
  stessa emozione. Solo riconoscimento visivo, nessuna parola da leggere.
- **La raccolta differenziata** (`games/recycle/RecycleGame.qml`) - drag come
  "Metti a posto" ma con 3 bidoni fissi (plastica/giallo, carta/blu,
  vetro/verde, i colori reali della differenziata) invece di regole che
  cambiano a turno: si trascinano 9 oggetti (bottiglie, carta, vetro) nel
  bidone giusto.
- **Il percorso delle forme** (`games/shapes/ShapesGame.qml`) - 5 file di
  sagome colorate (cerchio/quadrato/triangolo/stella); in alto una forma o un
  colore indica la regola del livello. Si tocca solo la casella giusta della
  fila attiva (le altre file sono bloccate finché non si arriva lì); ogni fila
  ha **una sola casella corretta**. Il personaggio (`Character`, riusato da
  "Il percorso") salta di fila in fila fino al traguardo 🏁. 8 livelli; le
  forme sono disegnate in `ShapeIcon.qml` (`Rectangle` per cerchio/quadrato,
  `Shape`/`ShapePath` per triangolo/stella).
- **Il serpente** (`games/snake/SnakeGame.qml`) - Snake a turni su una griglia
  6x6: avanza da solo (`Timer` che accelera un po' ad ogni livello); le
  frecce, o un tocco sul campo verso il lato voluto, cambiano solo la
  direzione (non si può invertire di colpo sul proprio collo). Mangia le mele
  e cresce; sbattere contro il muro o il proprio corpo è un errore ("Ops!
  Riprova", si torna alla partenza dello stesso livello). 6 livelli, da 3 a 5
  mele.

## Aggiungere un nuovo gioco

1. Crea `qml/games/<nome>/<Nome>Game.qml` con radice **`MiniGame`** (che dà già
   `exitRequested`, `restartRequested`, il pulsante avanti, `age`, `playerName`,
   `score`, `levelIndex`, `levelCount`, `mistakes`, `won`, il passaggio
   automatico di livello, `reward()`/`celebrate()`/`oops()`).
   - `SoundBank { id: snd }` dentro
   - `levelCount: N` e `onBuildLevel: (i) => load(i)`
   - `load(i)` imposta `levelIndex = i`, `won = false`, `mistakes = 0` e
     costruisce il livello
   - a risposta giusta finale: `snd.win(); win()`
   - a ogni errore: `snd.nope(); wrong()`
   (I giochi 1-5 usano ancora `GameScaffold` direttamente: è un pattern
   equivalente, un po' più verboso.)
2. Se serve logica pesante in C++, aggiungi una classe con `QML_ELEMENT` in
   `src/` (vedi `PathEngine`); altrimenti basta QML/JS.
3. Elenca il nuovo file in `CMakeLists.txt` (`QML_FILES`).
4. In `qml/Main.qml`: un `Component { id: xC; XGame { onExitRequested: ... } }`
   e una voce nella mappa di `openGame()`.
5. In `qml/Launcher.qml`: una riga nella lista `games` (`id`, `title`, `age`,
   `c` colore, `e` emoji).
