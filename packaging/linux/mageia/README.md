# Pacchetto RPM per Mageia

## Stato dell'immagine Docker

Al momento della creazione di questo pacchetto (settembre 2026) **Mageia 10
è disponibile come immagine Docker ufficiale** su Docker Hub:
`docker.io/library/mageia:10` (il tag `latest` punta allo stesso digest).
Verificato con:

```sh
docker pull mageia:10
docker run --rm mageia:10 cat /etc/mageia-release
# -> Mageia release 10 (Official) for x86_64
```

Quindi **non è stato necessario alcun proxy/sostituto**: `Dockerfile` e
`build.sh` in questa directory usano direttamente `FROM mageia:10` e la
build è stata eseguita ed è stata verificata con successo su questa
versione reale.

## Cosa controllare se in futuro `mageia:10` non fosse più disponibile

Se in una futura ricostruzione l'immagine `mageia:10` non fosse raggiungibile
(rimossa da Docker Hub, rinominata, ecc.), procedere così:

1. Elencare i tag disponibili per l'immagine ufficiale:
   `curl -s "https://hub.docker.com/v2/repositories/library/mageia/tags?page_size=50"`
   oppure `docker pull mageia:<tag>` per i tag più plausibili
   (`cauldron` = rolling/sviluppo, `9` = versione stabile precedente).
2. Scegliere come sostituto la versione stabile più vicina a quella target
   (es. `mageia:9`), e aggiornare `FROM mageia:9` nel `Dockerfile`.
3. Rieseguire da zero i comandi di verifica pacchetti usati per questo
   pacchetto, perché i nomi possono cambiare tra versioni:
   ```sh
   docker run --rm mageia:<tag> dnf -y makecache
   docker run --rm mageia:<tag> dnf -y search qt6
   docker run --rm mageia:<tag> dnf -y provides '*/qml/QtMultimedia/qmldir'
   ```
4. Aggiornare `giochi.spec` (BuildRequires/Requires) di conseguenza e
   ripetere la build con `build.sh`, controllando l'output di
   `rpm -qip` / `rpm -qlp` sul pacchetto risultante prima di considerarlo
   valido.
5. Quando Mageia 10 (o una versione più recente) tornerà disponibile come
   immagine ufficiale, riportare `FROM mageia:10` (o la nuova versione) e
   ripetere la verifica.

## Convenzioni di naming dei pacchetti Qt6 su Mageia

Mageia usa il prefisso `lib64` per i pacchetti delle librerie a 64 bit, a
differenza di Fedora (`qt6-qtbase-devel`) e openSUSE (`qt6-base-devel`):

- `lib64qt6base6-devel` — file di sviluppo per Qt6 Core/Gui/Widgets
- `lib64qt6qml-devel` — file di sviluppo per QtQml
- `lib64qt6quick-devel` — file di sviluppo per QtQuick

Il modulo QML QtMultimedia usato a runtime da `qml/common/SoundBank.qml`
(`import QtMultimedia`, per gli effetti sonori) è invece fornito dal
pacchetto **`qtmultimedia6`** (senza prefisso `lib64`, perché è un
"componente"/plugin QML e non una libreria condivisa in senso stretto) —
verificato con:

```sh
docker run --rm mageia:10 dnf -y provides '*/qml/QtMultimedia/qmldir'
```

che riporta il file come appartenente a `qtmultimedia6-6.10.0-1.mga10`.
Questo pacchetto **non** è richiesto in fase di build (il progetto non fa
`find_package(Qt6 COMPONENTS Multimedia)` né linka nulla di Multimedia:
lo usa solo via QML), quindi compare come `Requires:` runtime nello
`giochi.spec`, non come `BuildRequires:`.
