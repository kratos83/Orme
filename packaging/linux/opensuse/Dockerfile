# Build environment for the openSUSE Tumbleweed RPM package of "giochi"
# (GiochiCoding).
#
# Usage: see build.sh in this directory.

FROM opensuse/tumbleweed

# Package names verified inside an opensuse/tumbleweed container with:
#   zypper search qt6
#
# Note: CMakeLists.txt only does find_package(Qt6 ... COMPONENTS Quick Qml)
# and links Qt6::Quick / Qt6::Qml - QtMultimedia is used exclusively via a
# QML "import QtMultimedia" (qml/common/SoundBank.qml) for sound effects,
# never through CMake/C++, so qt6-multimedia-devel is not needed to
# configure or build (verified by building without it). qt6-multimedia-imports
# (the runtime QML plugin) is pulled in only as a runtime Requires in
# giochi.spec, not here - see the comment there for details.
RUN zypper --non-interactive refresh && \
    zypper --non-interactive install --no-recommends \
        cmake \
        gcc-c++ \
        rpm-build \
        rpmdevtools \
        qt6-base-devel \
        qt6-declarative-devel \
    && zypper clean --all

RUN rpmdev-setuptree

WORKDIR /work
