#!/usr/bin/env bash
# Build script per la APK Android di "Orme" (giochi-coding).
#
# Compila l'app QML/Qt6 esistente (target CMake "Orme", modulo QML "Giochi")
# per Android arm64-v8a usando un kit Qt per Android scaricato con aqtinstall
# e produce un APK (release, non firmato) in packaging/android/out/.
# Per un APK debug-signed basta aggiungere -DCMAKE_BUILD_TYPE=Debug e usare il
# target "Orme_make_apk" con il flavor debug (androiddeployqt firma
# automaticamente le build debug con il keystore di debug di default).
#
# Tutto cio' che manca (venv+aqtinstall, kit Qt Android/host, JDK portable,
# NDK) viene scaricato/installato automaticamente al primo avvio dentro
# packaging/android/ (qualche GB e alcuni minuti la prima volta; le run
# successive riusano quanto gia' presente). Non modifica nulla fuori da
# packaging/android (a parte leggere CMakeLists.txt nella root del repo).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"

# --- Percorsi/versioni dei tool -----------------------------------------
QT_VERSION="${QT_VERSION:-6.8.2}"
NDK_VERSION="${NDK_VERSION:-26.3.11579264}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/home/angelo/Android/SDK}"
ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-$ANDROID_SDK_ROOT/ndk/$NDK_VERSION}"
QT_DIR="$HERE/Qt"
QT_ANDROID_DIR="$QT_DIR/$QT_VERSION/android_arm64_v8a"
# Qt6 desktop "host", stessa versione del kit Android, scaricato con aqt (il
# Qt6 di sistema/Debian non va bene come QT_HOST_PATH: il suo layout cmake
# multiarch non fornisce il pacchetto Qt6HostInfo richiesto dal toolchain Qt
# per il cross-compiling verso Android).
QT_HOST_DIR="${QT_HOST_DIR:-$QT_DIR/$QT_VERSION/gcc_64}"
QT_HOST_CMAKE_DIR="${QT_HOST_CMAKE_DIR:-$QT_HOST_DIR/lib/cmake/Qt6}"
VENV_DIR="$HERE/.venv"
AQT="$VENV_DIR/bin/aqt"
JDK_DIR="$HERE/jdk"

# BUILD_TYPE=Release (default) produce un APK release non firmato;
# BUILD_TYPE=Debug produce un APK debug firmato automaticamente da
# androiddeployqt/gradle con il keystore di debug standard (installabile
# subito con "adb install", niente firma manuale richiesta).
BUILD_TYPE="${BUILD_TYPE:-Release}"
BUILD_DIR="$HERE/build-android-$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')"
OUT_DIR="$HERE/out"

# --- Installazione automatica delle dipendenze mancanti ------------------

if [ ! -x "$AQT" ]; then
    echo "== venv/aqtinstall non trovati: li creo in $VENV_DIR =="
    # Niente modulo "ensurepip" di sistema (python3-venv incompleto su questa
    # macchina) e niente sudo per installarlo: bootstrap di pip a mano con
    # get-pip.py, poi aqtinstall dentro il venv.
    python3 -m venv --without-pip "$VENV_DIR"
    curl -fsSL https://bootstrap.pypa.io/get-pip.py -o "$VENV_DIR/get-pip.py"
    "$VENV_DIR/bin/python3" "$VENV_DIR/get-pip.py" --quiet
    rm -f "$VENV_DIR/get-pip.py"
    "$VENV_DIR/bin/pip" install --quiet aqtinstall
fi

if [ ! -d "$QT_ANDROID_DIR" ]; then
    echo "== Scarico Qt $QT_VERSION per Android arm64-v8a (una volta sola) =="
    "$AQT" install-qt all_os android "$QT_VERSION" android_arm64_v8a \
        -O "$QT_DIR" -m qtshadertools qtmultimedia
fi

if [ ! -d "$QT_HOST_DIR" ]; then
    echo "== Scarico Qt $QT_VERSION desktop come 'host' per il toolchain Android =="
    "$AQT" install-qt linux desktop "$QT_VERSION" linux_gcc_64 \
        -O "$QT_DIR" -m qtshadertools qtmultimedia
fi

if [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo "== Installo l'NDK $NDK_VERSION via sdkmanager =="
    "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --install "ndk;$NDK_VERSION"
fi

JDK_HOME=$(find "$JDK_DIR" -maxdepth 1 -iname 'jdk-*' -type d 2>/dev/null | head -n1)
if [ -z "$JDK_HOME" ] || [ ! -x "$JDK_HOME/bin/java" ]; then
    echo "== Scarico un JDK 17 portable (Eclipse Temurin) =="
    mkdir -p "$JDK_DIR"
    curl -fsSL "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse?project=jdk" \
        -o "$JDK_DIR/temurin17.tar.gz"
    tar -xzf "$JDK_DIR/temurin17.tar.gz" -C "$JDK_DIR"
    rm -f "$JDK_DIR/temurin17.tar.gz"
    JDK_HOME=$(find "$JDK_DIR" -maxdepth 1 -iname 'jdk-*' -type d | head -n1)
fi

export JAVA_HOME="$JDK_HOME"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_SDK_ROOT
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_NDK_ROOT
export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"
export QT_HOST_PATH="$QT_HOST_DIR"

QT_TOOLCHAIN="$QT_ANDROID_DIR/lib/cmake/Qt6/qt.toolchain.cmake"

echo "== Configurazione CMake (Android arm64-v8a, Qt $QT_VERSION) =="
cmake -S "$REPO_ROOT" -B "$BUILD_DIR" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_TOOLCHAIN_FILE="$QT_TOOLCHAIN" \
    -DQT_HOST_PATH="$QT_HOST_PATH" \
    -DQT_HOST_PATH_CMAKE_DIR="$QT_HOST_CMAKE_DIR" \
    -DANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
    -DANDROID_NDK_ROOT="$ANDROID_NDK_ROOT" \
    -DQT_ANDROID_BUILD_ALL_ABIS=OFF \
    -DANDROID_ABI=arm64-v8a \
    -DQT_ANDROID_ABIS=arm64-v8a \
    -DCMAKE_FIND_ROOT_PATH="$QT_ANDROID_DIR" \
    -DCMAKE_PROJECT_INCLUDE="$HERE/cmake_hooks/android_install_fix.cmake"

echo "== Build C++ (target Orme) =="
cmake --build "$BUILD_DIR" -j

echo "== Generazione APK (androiddeployqt) =="
cmake --build "$BUILD_DIR" --target Orme_make_apk

mkdir -p "$OUT_DIR"
APK_SRC=$(find "$BUILD_DIR" -iname "*.apk" -path "*apk/debug*" | head -n1)
if [ -z "$APK_SRC" ]; then
    APK_SRC=$(find "$BUILD_DIR" -iname "*.apk" | head -n1)
fi

if [ -z "$APK_SRC" ]; then
    echo "Errore: nessun APK generato." >&2
    exit 1
fi

cp -v "$APK_SRC" "$OUT_DIR/"
echo "== Fatto. APK in: $OUT_DIR/$(basename "$APK_SRC") =="
