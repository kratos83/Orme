# Pacchettizzazione multi-piattaforma

## Numero di versione: un solo file

Il file [`VERSION.txt`](../VERSION.txt) alla radice del repo è l'**unica**
fonte del numero di versione. Per rilasciare una nuova versione si modifica
solo quello (es. `0.5`), poi si committa e si tagga `v0.5` — nessun altro
file va più toccato a mano:

- **CMake/l'app stessa**: `CMakeLists.txt` legge `VERSION.txt` all'avvio
  della configurazione (`file(STRINGS ...)`) e la propaga a
  `PROJECT_VERSION`, da cui derivano sia `app.applicationVersion()`/
  `Updater` (via `ORME_VERSION`) sia, tramite `androiddeployqt`,
  `versionName`/`versionCode` di Android.
  ⚠️ Il nome è `VERSION.txt` e non `VERSION`: su filesystem
  case-insensitive (Windows, macOS) un file chiamato `VERSION` collide con
  l'header standard C++ `<version>`, perché la radice del repo è nel path
  di include del progetto — è già successo, build rotta su entrambe le
  piattaforme.
- **Windows**: `windows.yml` prende la versione direttamente dal tag git
  push (`v0.5` → `0.5`) e la passa a Inno Setup con `/DMyAppVersion=...`.
- **Arch / Alpine**: `PKGBUILD`/`APKBUILD` leggono `VERSION.txt` direttamente
  (`pkgver=$(cat .../VERSION.txt)`), sono script bash veri.
- **Fedora / openSUSE / Mageia**: i rispettivi `build.sh` sincronizzano da
  soli il campo `Version:` dello `.spec` da `VERSION.txt` prima di buildare
  (`sed -i "s/^Version:.*/Version: .../"`).
- **Debian**: `packaging/linux/debian/build.sh` legge `VERSION.txt` e, se
  diversa dall'ultima voce di `debian/changelog`, ne aggiunge una nuova in
  cima con data di oggi (non riscrive quella vecchia).

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
| Windows (MSVC)        | `.zip` portable| ✅ Verificata | `.github/workflows/windows.yml` |
| Windows (installer)   | `.exe`         | ✅ Verificata | `.github/workflows/windows.yml` |
| macOS (universale)    | `.dmg`         | ✅ Verificata | `.github/workflows/macos.yml` |

Windows e macOS non sono compilabili in modo affidabile da questa macchina
Linux (nessuna vera macchina Windows/macOS disponibile): i workflow sono
pronti e usano ricette standard (Qt via `jurplel/install-qt-action`,
`windeployqt`/`macdeployqt`), ma la prima esecuzione reale avverrà solo
quando il repository sarà pubblicato su GitHub e la Action gireà sulle
macchine cloud reali di GitHub Actions.

## Repository apt/rpm (aggiornamenti automatici)

Debian/Ubuntu e le tre distro rpm (Fedora/openSUSE/Mageia) hanno anche un
vero repository di sistema, non solo il pacchetto scaricabile dalle
Release: installando `.deb`/`.rpm` si abilita da solo, cosi' le versioni
future arrivano con `apt upgrade`/`dnf update`/`zypper update`. Vedi
[packaging/repo/README.md](repo/README.md) per i dettagli, inclusa la
configurazione una tantum (Pages + secret GPG) che solo chi amministra il
repository GitHub può fare. Arch e Alpine restano volutamente fuori da
questo meccanismo.


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
