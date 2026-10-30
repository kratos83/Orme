# Pacchetto Arch Linux — Orme (orme)

## Nome del pacchetto

`pkgname=orme` (uguale al nome del binario/target CMake), non `orme`:
"Orme" è solo il nome visualizzato (titolo finestra, `setApplicationName`),
mentre il progetto CMake, il modulo QML e l'eseguibile si chiamano tutti
`orme`/`orme`. Usare lo stesso nome per il pacchetto evita ambiguità fra
`pacman -S orme` e il comando/binario installato (`/usr/bin/orme`).

## Pacchetti Qt6 verificati

Verificati dentro un container `archlinux:latest` con `pacman -Ss qt6` e
`pacman -Si qt6-multimedia`:

- `qt6-base`, `qt6-declarative`, `qt6-multimedia` sono tutti nel repo
  `extra` di Arch (versione testata: 6.11.2).
- `qt6-multimedia` dichiara una dipendenza virtuale `qt6-multimedia-backend`,
  soddisfatta da uno tra `qt6-multimedia-ffmpeg` o `qt6-multimedia-gstreamer`
  (pacman chiede quale usare, o sceglie il default con `--noconfirm`). Nel
  Dockerfile si installa esplicitamente `qt6-multimedia-ffmpeg`.

`depends=('qt6-base' 'qt6-declarative' 'qt6-multimedia')` nel PKGBUILD è
quindi corretto e completo (pacman risolverà da solo il backend multimedia
richiesto da `qt6-multimedia` all'installazione).

## Come funziona la build

`makepkg` non può girare come root: il `Dockerfile` crea un utente
`builder` con sudo senza password limitato a `pacman` (necessario solo se
`makepkg` viene invocato con `--syncdeps`, che prova a usare `sudo pacman`
per installare dipendenze mancanti — qui non serve perché tutte le
dipendenze sono già nell'immagine, ma è configurato per correttezza).

Il codice sorgente non viene scaricato da rete: il `Dockerfile` copia
l'albero del repo (`CMakeLists.txt`, `COPYRIGHT`, `src/`, `qml/`, `assets/`)
dentro l'immagine in `/home/builder/orme-source` *prima* di eseguire
`makepkg`. Il `PKGBUILD` ha quindi `source=()` e build()/package() puntano
direttamente a quella directory invece di scaricare un tarball.

Eseguire:

```bash
./build.sh
```

Costruisce l'immagine Docker, lancia `makepkg` come utente `builder` dentro
un container, e copia il risultato in `../../out/arch/`.

## Build verificata

Eseguita realmente il 2026-09-11 dentro Docker (Arch Linux aggiornato al
momento del test, Qt 6.11.2):

```
==> Finished making: orme 0.1-1 (Fri Sep 11 05:09:51 2026)
```

Pacchetti prodotti:
- `orme-0.1-1-x86_64.pkg.tar.zst` (~517 KiB)
- `orme-debug-0.1-1-x86_64.pkg.tar.zst` (~6.9 MiB, simboli di debug —
  generato automaticamente da makepkg/base-devel, non è un errore)

Verifica del pacchetto (in un secondo container Arch pulito):

```
$ pacman -Qip orme-0.1-1-x86_64.pkg.tar.zst
Name            : orme
Version         : 0.1-1
Depends On      : qt6-base  qt6-declarative  qt6-multimedia
...

$ pacman -Qlp orme-0.1-1-x86_64.pkg.tar.zst
orme /usr/bin/orme
orme /usr/share/licenses/orme/COPYRIGHT
```

Installazione reale (`pacman -U`) in un container pulito, poi:

```
$ file /usr/bin/orme
/usr/bin/orme: ELF 64-bit LSB pie executable, x86-64, ... dynamically linked, ... stripped

$ ldd /usr/bin/orme | grep 'not found'
(nessun output -> nessuna libreria mancante)
```

Non è stato possibile lanciare l'interfaccia grafica dentro il container
(nessun display/Wayland/X11 disponibile in questo ambiente headless): la
verifica si è fermata a installazione + linking dinamico completo, che è
comunque una prova concreta che il pacchetto è corretto e tutte le
dipendenze runtime sono risolte.
