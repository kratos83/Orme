# Pacchetto Alpine Linux — Orme (orme)

## Nome del pacchetto

`pkgname=orme`, per coerenza con il pacchetto Arch e con il nome del
binario installato (`/usr/bin/orme`); "Orme" resta solo il nome
visualizzato dall'app (vedi `pkgdesc`).

## Repository/versione Alpine e pacchetti Qt6 verificati

I pacchetti Qt6 **non esistono affatto** nei repository stabili di Alpine
(3.x `main`/`community`): sono disponibili solo su **alpine:edge**, nel
repo **community** (verificato dentro un container `alpine:edge` con
`apk search qt6` e `apk policy <pacchetto>`):

| Pacchetto                    | Versione testata | Repo            |
|-------------------------------|------------------|-----------------|
| `qt6-qtbase-dev`               | 6.11.1-r2        | edge/community  |
| `qt6-qtdeclarative-dev`        | 6.11.1-r1        | edge/community  |
| `qt6-qtmultimedia-dev`         | 6.11.1-r0        | edge/community  |
| `qt6-qtmultimedia` (runtime)   | 6.11.1-r0        | edge/community  |
| `qt6-qtmultimedia-ffmpeg`      | 6.11.1-r0        | edge/community  |
| `qt6-qtbase` (runtime)         | 6.11.1-r2        | edge/community  |
| `qt6-qtdeclarative` (runtime)  | 6.11.1-r1        | edge/community  |
| `cmake`, `build-base`, `samurai`, `alpine-sdk`, `sudo` | - | edge/main / edge/community |

Nota sui nomi: su Alpine i pacchetti Qt6 usano il prefisso `qt6-qt<modulo>`
(es. `qt6-qtbase`, `qt6-qtdeclarative`, `qt6-qtmultimedia`), diverso dallo
schema Arch (`qt6-base`, `qt6-declarative`, `qt6-multimedia`). Il file
`APKBUILD` usa quindi:

```
depends="qt6-qtbase qt6-qtdeclarative qt6-qtmultimedia"
makedepends="cmake samurai build-base qt6-qtbase-dev qt6-qtdeclarative-dev qt6-qtmultimedia-dev"
```

`samurai` (l'implementazione Alpine di Ninja) è necessario perché
`abuild` imposta di default `CMAKE_GENERATOR=Ninja`
(`/usr/share/abuild/default.conf`); senza `samurai` installato la
configurazione CMake fallisce con "CMake was unable to find a build
program corresponding to Ninja" (riscontrato durante il primo tentativo
di build, poi risolto aggiungendo il pacchetto).

## Come funziona la build

`abuild` non può girare come root: il `Dockerfile` crea un utente
`builder` nel gruppo `abuild`, con sudo senza password (necessario perché
`abuild-keygen -i` installa la chiave pubblica in `/etc/apk/keys` tramite
`sudo cp`/`sudo mkdir`). La chiave di firma viene generata una volta sola
al build dell'immagine con `abuild-keygen -a -i -n`.

Il codice sorgente non viene scaricato da rete: il `Dockerfile` copia
l'albero del repo dentro l'immagine in `/home/builder/orme-source` prima
di eseguire `abuild`. L'`APKBUILD` ha `source=""` e un `unpack()`
personalizzato che copia da lì invece di scaricare/estrarre un tarball.

Eseguire:

```bash
./build.sh
```

Costruisce l'immagine Docker, lancia `abuild -r` come utente `builder`
dentro un container, e copia il risultato (.apk) in `../../out/alpine/`.

## Build verificata

Eseguita realmente il 2026-09-11 dentro Docker (alpine:edge, Qt 6.11.1):

```
>>> orme*: Create orme-0.1-r0.apk
>>> orme: Build complete at Fri, 11 Sep 2026 05:21:02 +0000 elapsed time 0h 0m 28s
```

Pacchetto prodotto: `orme-0.1-r0.apk` (~544 KiB).

Verifica del contenuto (un `.apk` Alpine è un tar.gz):

```
$ tar -tzf orme-0.1-r0.apk
.PKGINFO
.SIGN.RSA.-6aa38ed7.rsa.pub
usr/bin/orme
usr/share/licenses/orme/COPYRIGHT
```

Installazione reale in un secondo container `alpine:edge` pulito
(`apk add --allow-untrusted`, dato che la chiave di firma è generata al
volo e non è nell'immagine "pulita" di verifica):

```
$ apk add --no-cache --allow-untrusted orme-0.1-r0.apk
...
(112/112) Installing orme (0.1-r0)
OK: 404.1 MiB in 128 packages

$ apk info -e orme
orme

$ file /usr/bin/orme
/usr/bin/orme: ELF 64-bit LSB pie executable, x86-64, ... interpreter /lib/ld-musl-x86_64.so.1, stripped

$ ldd /usr/bin/orme | grep 'not found'
(nessun output -> nessuna libreria mancante)
```

`apk` ha risolto da solo tutte le dipendenze Qt6 (qt6-qtbase, qt6-qtsvg,
qt6-qtdeclarative, qt6-qtmultimedia, mesa, alsa-lib, libpulse, ecc.),
confermando che `depends=` nell'APKBUILD è corretto.

Anche qui non è stato possibile lanciare l'interfaccia grafica in questo
ambiente headless: la verifica si ferma a installazione + linking
dinamico completo (nessuna libreria mancante), che è comunque una prova
concreta di validità del pacchetto.
