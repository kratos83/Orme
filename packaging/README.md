# Pacchettizzazione multi-piattaforma

Stato di avanzamento per ciascuna piattaforma richiesta. Tutte le build
elencate come "verificata" sono state **eseguite per davvero** (non solo
scritte a mano) e il pacchetto risultante è stato ispezionato e/o installato
per confermare che dipendenze e contenuti siano corretti.

Nota importante: gli script di build dei pacchetti Linux (`build.sh`) creano
il tarball sorgente con `git archive HEAD`, quindi **vanno eseguiti dopo aver
committato le modifiche** — non impacchettano file non ancora committati.

| Piattaforma          | Formato        | Stato          | Dove |
|-----------------------|----------------|----------------|------|
| Debian / Ubuntu       | `.deb`         | ✅ Verificata  | `debian/` (build con `dpkg-buildpackage -us -uc -b`, root del repo) |
| Fedora                | `.rpm`         | ✅ Verificata  | `packaging/linux/fedora/` |
| openSUSE Tumbleweed   | `.rpm`         | ✅ Verificata  | `packaging/linux/opensuse/` |
| Mageia 10             | `.rpm`         | ✅ Verificata  | `packaging/linux/mageia/` |
| Arch Linux            | `.pkg.tar.zst` | ✅ Verificata  | `packaging/linux/arch/` |
| Alpine Linux          | `.apk`         | ✅ Verificata  | `packaging/linux/alpine/` |
| Android (arm64-v8a)   | `.apk`         | ✅ Verificata  | `packaging/android/` |
| Windows (MSVC)        | `.zip` portable| ⏳ Pronta, da eseguire su CI | `.github/workflows/windows.yml` |
| macOS (universale)    | `.dmg`         | ⏳ Pronta, da eseguire su CI | `.github/workflows/macos.yml` |

Windows e macOS non sono compilabili in modo affidabile da questa macchina
Linux (nessuna vera macchina Windows/macOS disponibile): i workflow sono
pronti e usano ricette standard (Qt via `jurplel/install-qt-action`,
`windeployqt`/`macdeployqt`), ma la prima esecuzione reale avverrà solo
quando il repository sarà pubblicato su GitHub e la Action gireà sulle
macchine cloud reali di GitHub Actions.

## Perché nomi diversi (`orme` vs `giochi`)

Il pacchetto Debian si chiama `orme` (nome pubblico dell'app), mentre i
pacchetti Fedora/openSUSE/Mageia/Arch/Alpine usano `giochi` (nome del
binario/target CMake). Sono equivalenti in sostanza; in una pubblicazione
definitiva conviene scegliere un nome unico per tutte le distro — ma questo
richiede una decisione del progetto, non tecnica.

## Una scoperta comune a tutte le distro Linux

Il progetto compila linkando solo `Qt6::Quick`/`Qt6::Qml` (niente
`find_package(... Multimedia)`), ma usa `QtMultimedia` **solo via QML**
(`import QtMultimedia` in `qml/common/SoundBank.qml`, per i 4 effetti
sonori). Questo significa che:

- non serve alcun `-devel`/`-dev` di QtMultimedia in fase di build (verificato
  buildando senza, su ogni distro);
- il pacchetto runtime del plugin QML di QtMultimedia va però dichiarato **a
  mano** come dipendenza esplicita, perché non compare nelle dipendenze ELF
  automatiche (uso QML-only) — e il nome di questo pacchetto **cambia da
  distro a distro** (`qt6-qtmultimedia` su Fedora, `qt6-multimedia-imports`
  su openSUSE, `qtmultimedia6` su Mageia, `qt6-multimedia`/`qt6-qtmultimedia`
  su Arch/Alpine, `qml6-module-qtmultimedia` su Debian). Ogni ricetta di
  build in questo repo dichiara quello giusto per la propria distro,
  verificato dentro un container reale — mai indovinato.

## Come compilare ciascun pacchetto Linux localmente

Serve Docker (tranne per Debian, nativo su questa macchina):

```bash
# Debian/Ubuntu (build nativa, nella radice del repo)
dpkg-buildpackage -us -uc -b
# -> ../orme_<versione>_amd64.deb

# Le altre distro (ognuna builda in un container Docker dedicato)
packaging/linux/fedora/build.sh
packaging/linux/opensuse/build.sh
packaging/linux/mageia/build.sh
packaging/linux/arch/build.sh
packaging/linux/alpine/build.sh
# -> pacchetti in packaging/out/<distro>/
```

## Android

```bash
# Prima volta: scarica Qt per Android + JDK portable in packaging/android/
# (vedi i commenti in build.sh per i comandi aqtinstall esatti)
packaging/android/build.sh            # BUILD_TYPE=Release di default -> APK non firmato
BUILD_TYPE=Debug packaging/android/build.sh  # APK debug, già firmato, installabile con adb
# -> packaging/android/out/*.apk
```

## Windows e macOS (via GitHub Actions)

Una volta che il repository è su GitHub, i workflow in `.github/workflows/`
(`windows.yml`, `macos.yml`) girano automaticamente a ogni push su `master`,
su ogni tag `v*` e possono anche essere lanciati a mano (tab "Actions" →
"Run workflow"). Gli artefatti compilati si scaricano dalla pagina della
run, sotto "Artifacts".

macOS: il `.dmg` prodotto **non è firmato né notarizzato** (servirebbe un
account Apple Developer a pagamento) — al primo avvio Gatekeeper avviserà
"sviluppatore non identificato": si apre comunque con tasto destro → Apri.
