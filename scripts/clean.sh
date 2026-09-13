#!/usr/bin/env bash
# Rimuove i file generati dalla compilazione: la cartella build/ E gli
# artefatti generati da CMake (compresi quelli di una eventuale
# configurazione IN-SOURCE finita nella radice del progetto).
#
#   scripts/clean.sh          pulizia normale
#   scripts/clean.sh --all    + elimina altre cartelle di build
#                             (build-*, *-build, cmake-build-*), i residui
#                             di dpkg-buildpackage, i pacchetti generati in
#                             packaging/out/, Qt per Android + JDK scaricati
#                             in packaging/android/ e le immagini Docker
#                             usate per compilare i pacchetti rpm/pkg/apk
#                             (libera diversi GB, ma la prossima build di
#                             quel tipo dovrà riscaricare/reinstallare tutto)
#
# I sorgenti (src/, qml/, assets/, scripts/, CMakeLists.txt, README.md) non
# vengono mai toccati.
#Copyright (C) Angelo Scarnà
set -euo pipefail

# radice del progetto = cartella che contiene questo script, un livello sopra
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

removed=0
zap() {
    for p in "$@"; do
        if [ -e "$p" ] || [ -L "$p" ]; then
            rm -rf -- "$p"
            echo "  rimosso  $p"
            removed=1
        fi
    done
}

echo "Pulizia in $root"

# cartella di build canonica (out-of-source)
zap build

# artefatti generati da CMake / Qt in una configurazione in-source
zap CMakeFiles CMakeCache.txt cmake_install.cmake install_manifest.txt \
    CTestTestfile.cmake DartConfiguration.tcl \
    Makefile compile_commands.json .ninja_deps .ninja_log build.ninja \
    giochi giochi_autogen giochi_qmltyperegistrations.cpp \
    Orme meta_types qmltypes .qt .rcc .qmlls.ini Orme Orme_autogen orme_qmltyperegistrations.cpp \
    aqtinstall.log .qmake.stash .qmake.cache .qmake.super .qmake.cache.shared 

if [ "${1:-}" = "all" ]; then
    for d in build-* *-build cmake-build-*; do
        [ -d "$d" ] && zap "$d"
    done

    # residui di dpkg-buildpackage nell'albero sorgente (root del repo)
    for d in obj-*-linux-gnu*; do
        [ -e "$d" ] && zap "$d"
    done
    zap debian/orme debian/.debhelper debian/debhelper-build-stamp debian/files
    for f in debian/*.substvars; do
        [ -e "$f" ] && zap "$f"
    done

    # pacchetti gia' generati e download/build pesanti del packaging
    zap packaging/out
    zap packaging/android/Qt packaging/android/jdk packaging/android/.venv \
        packaging/android/out packaging/android/aqtinstall.log
    for d in packaging/android/build-android-*; do
        [ -e "$d" ] && zap "$d"
    done

    # immagini Docker create per compilare i pacchetti rpm/pkg/apk
    if command -v docker >/dev/null 2>&1; then
        images="giochi-fedora-builder giochi-opensuse-builder giochi-mageia-builder orme-arch-builder orme-alpine-builder orme-debian-builder"
        present=""
        for img in $images; do
            docker image inspect "$img" >/dev/null 2>&1 && present="$present $img"
        done
        if [ -n "$present" ]; then
            # shellcheck disable=SC2086
            docker rmi -f $present >/dev/null
            echo "  rimosse immagini docker: $present"
            removed=1
        fi
    fi
fi

if [ "$removed" -eq 0 ]; then
    echo "  niente da rimuovere: gia' pulito"
fi
