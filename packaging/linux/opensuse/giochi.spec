Name:           orme-opensuse
Version:        0.1
Release:        1
Summary:        Orme - raccolta di mini-giochi educativi per bambini (Qt6/QML)

# Niente sottopacchetti -debuginfo/-debugsource: non servono agli utenti
# finali e altrimenti finiscono anche loro tra gli allegati della release.
%global debug_package %{nil}

License:        GPL-3.0-or-later
URL:            https://example.invalid/giochi-coding
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake >= 3.21
BuildRequires:  gcc-c++
BuildRequires:  qt6-base-devel >= 6.5
BuildRequires:  qt6-declarative-devel >= 6.5
# No qt6-multimedia-devel BuildRequires: CMakeLists.txt only does
# find_package(Qt6 ... COMPONENTS Quick Qml) and links Qt6::Quick/Qt6::Qml.
# QtMultimedia is used solely via a QML "import QtMultimedia" statement, so
# nothing at build/link time needs its devel package (verified by building
# successfully without it installed).

# QtMultimedia's QML plugin (qml/QtMultimedia/*.so + qmldir) is used at
# runtime by qml/common/SoundBank.qml (import QtMultimedia) for sound
# effects. It is not linked at the library level (QML-only usage), so it
# does not show up in automatic ELF-dependency detection and must be
# declared by hand. On openSUSE Tumbleweed this plugin lives in its own
# subpackage, qt6-multimedia-imports (verified with
# `rpm -ql qt6-multimedia-imports` in an opensuse/tumbleweed container) -
# unlike Fedora, where it ships inside the main qt6-qtmultimedia package.
Requires:       qt6-multimedia-imports

%description
Orme e' una raccolta di 20 mini-giochi touch pensati per bambini di 3-5
anni, ispirati ai concetti base della programmazione (percorsi, sequenze,
cicli, ordinamento, ecc). Applicazione Qt6/QML pura (Quick + Qml), con
effetti sonori riprodotti tramite il modulo QML QtMultimedia.

%prep
%autosetup -n %{name}-%{version}

%build
%cmake -DCMAKE_BUILD_TYPE=Release
%cmake_build

%install
%cmake_install

%files
%license LICENSE
%doc COPYRIGHT
%{_bindir}/Orme
%{_datadir}/applications/orme.desktop
%{_datadir}/icons/hicolor/scalable/apps/orme.svg

%changelog
* Fri Sep 11 2026 Angelo Scarna <angelo.scarna@primanotanet.it> - 0.1-1
- Pacchetto RPM iniziale per openSUSE Tumbleweed.
