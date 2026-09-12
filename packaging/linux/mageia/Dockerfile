# Build environment for the Mageia 10 RPM package of "giochi" (GiochiCoding).
#
# Mageia 10 is available as an OFFICIAL Docker image (docker.io/library/mageia,
# tags "10" and "latest" both resolve to the same digest as of 2026-09) - no
# proxy/substitute distro version was needed here. See README.md in this
# directory for what to do if that ever changes.
#
# Usage: see build.sh in this directory.

FROM mageia:10

# Package names verified inside a mageia:10 container with:
#   dnf search qt6
#   dnf provides '*/qml/QtMultimedia/qmldir'
#
# Mageia uses the "lib64<name>-devel" naming convention for x86_64 library
# devel packages (its "particular prefix conventions", as expected):
#   lib64qt6base6-devel     -> Qt6 Core/Gui/Widgets etc. development files
#   lib64qt6qml-devel       -> QtQml development files
#   lib64qt6quick-devel     -> QtQuick development files
#
# Note: CMakeLists.txt only does find_package(Qt6 ... COMPONENTS Quick Qml)
# and links Qt6::Quick / Qt6::Qml - QtMultimedia is used exclusively via a
# QML "import QtMultimedia" (qml/common/SoundBank.qml) for sound effects,
# never through CMake/C++, so no multimedia devel package is needed here
# (verified by configuring+building without one installed). The runtime-only
# QtMultimedia QML plugin is declared as a plain Requires in giochi.spec
# instead - see the comment there for exactly which Mageia package owns it
# (unusually, it is NOT one of the "lib64qt6multimedia*" packages).
RUN dnf -y install \
        cmake \
        gcc-c++ \
        rpm-build \
        rpmdevtools \
        lib64qt6base6-devel \
        lib64qt6qml-devel \
        lib64qt6quick-devel \
    && dnf clean all

RUN rpmdev-setuptree

WORKDIR /work
