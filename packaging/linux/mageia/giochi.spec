Name:           orme-mageia
Version:        0.4
Release:        1%{?dist}
Summary:        Orme - raccolta di mini-giochi educativi per bambini (Qt6/QML)

# Niente sottopacchetti -debuginfo/-debugsource: non servono agli utenti
# finali e altrimenti finiscono anche loro tra gli allegati della release.
%global debug_package %{nil}

License:        GPL-3.0-or-later
URL:            https://github.com/kratos83/Orme
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake >= 3.21
BuildRequires:  gcc-c++
BuildRequires:  lib64qt6base6-devel >= 6.5
BuildRequires:  lib64qt6qml-devel >= 6.5
BuildRequires:  lib64qt6quick-devel >= 6.5
# No multimedia devel BuildRequires: CMakeLists.txt only does
# find_package(Qt6 ... COMPONENTS Quick Qml) and links Qt6::Quick/Qt6::Qml.
# QtMultimedia is used solely via a QML "import QtMultimedia" statement, so
# nothing at build/link time needs a multimedia devel package (verified by
# configuring+building successfully without one installed).

# QtMultimedia's QML plugin (qml/QtMultimedia/*.so + qmldir) is used at
# runtime by qml/common/SoundBank.qml (import QtMultimedia) for sound
# effects. It is not linked at the library level (QML-only usage), so it
# does not show up in automatic ELF-dependency detection and must be
# declared by hand. On Mageia 10 this plugin is owned by the package
# "qtmultimedia6" (verified with
# `dnf provides '*/qml/QtMultimedia/qmldir'` in a mageia:10 container) -
# note this does NOT follow the usual "lib64qt6..." naming convention used
# by the Qt6 library/devel packages on this distro, since it is a
# QML-component/plugin package rather than a shared library.
Requires:       qtmultimedia6

%description
Orme e' una raccolta di 45 mini-giochi touch per bambini di 3-10 anni:
giochi per l'infanzia ispirati ai concetti base della programmazione
(percorsi, sequenze, cicli, ordinamento, ecc) e giochi di matematica,
italiano e geografia per la primaria. Applicazione Qt6/QML pura
(Quick + Qml), con effetti sonori riprodotti tramite il modulo QML
QtMultimedia. Abilita anche il repository RPM di Orme, cosi' gli
aggiornamenti futuri arrivano con i normali "dnf update" del sistema.

%prep
%autosetup -n %{name}-%{version}

%build
%cmake -DCMAKE_BUILD_TYPE=Release
%cmake_build

%install
%cmake_install
# Abilita il repository RPM di Orme (vedi packaging/repo/README.md): il
# file .repo e la chiave pubblica GPG vengono installati dal pacchetto
# stesso, cosi' "dnf update" trova da solo le versioni future.
install -Dm644 packaging/repo/orme-mageia.repo %{buildroot}%{_sysconfdir}/yum.repos.d/orme.repo
install -Dm644 packaging/repo/orme-archive-keyring.asc %{buildroot}%{_datadir}/orme/orme-archive-keyring.asc

%post
# Pre-importa la chiave dal file shipped nel pacchetto (non da rete, cosi'
# funziona anche offline): evita il prompt interattivo "import this key?"
# al primo "dnf update" dal repo Orme. Fallisce in modo innocuo se rpm non
# e' disponibile in questo contesto.
rpm --import %{_datadir}/orme/orme-archive-keyring.asc >/dev/null 2>&1 || :

%files
%license LICENSE
%doc COPYRIGHT
%{_bindir}/Orme
%{_datadir}/applications/orme.desktop
%{_datadir}/icons/hicolor/scalable/apps/orme.svg
%config(noreplace) %{_sysconfdir}/yum.repos.d/orme.repo
%{_datadir}/orme/orme-archive-keyring.asc

%changelog
* Fri Sep 11 2026 Angelo Scarna <angelo.scarna@primanotanet.it> - 0.1-1
- Pacchetto RPM iniziale per Mageia 10.
