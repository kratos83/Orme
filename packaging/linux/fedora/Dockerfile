# Build environment for the Fedora RPM package of "giochi" (GiochiCoding).
#
# Usage: see build.sh in this directory. This Dockerfile only prepares the
# rpmbuild tree and toolchain; the actual RPM is built by build.sh invoking
# `rpmbuild -ba` inside a container based on this image, with the project
# source tree bind-mounted / copied in at build time.

FROM fedora:latest

# Toolchain + Qt6 development packages needed to configure/build the project,
# plus rpm packaging tools.
#
# Package names verified inside a fedora:latest (Fedora 44) container with:
#   dnf search qt6
#
# Note: CMakeLists.txt only does find_package(Qt6 ... COMPONENTS Quick Qml)
# and links Qt6::Quick / Qt6::Qml - QtMultimedia is used exclusively via a
# QML "import QtMultimedia" (qml/common/SoundBank.qml) for sound effects,
# never through CMake/C++, so no qt6-qtmultimedia*-devel package is needed
# to configure or build (verified by building without it). It IS needed at
# *runtime*, which is why it appears as a plain Requires in giochi.spec
# instead of a BuildRequires here - see the comment there for exactly which
# Fedora package ships that runtime QML plugin.
RUN dnf -y install \
        cmake \
        gcc-c++ \
        rpm-build \
        rpmdevtools \
        qt6-qtbase-devel \
        qt6-qtdeclarative-devel \
    && dnf clean all

# Prepare the standard rpmbuild directory tree for the build user.
RUN rpmdev-setuptree

WORKDIR /work
