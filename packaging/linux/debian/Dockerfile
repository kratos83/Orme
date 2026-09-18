# Ambiente di build per il pacchetto Debian di "Orme" (eseguibile: Orme).
#
# Usiamo debian:trixie-slim (non l'immagine ubuntu del runner GitHub Actions)
# perche' Ubuntu ferma Qt6 a una versione < 6.5, sotto il minimo richiesto sia
# da debian/control (Build-Depends: qt6-base-dev (>= 6.5), ...) sia da
# CMakeLists.txt (find_package(Qt6 6.5 REQUIRED ...)).
FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        debhelper \
        cmake \
        qt6-base-dev \
        qt6-declarative-dev \
    && rm -rf /var/lib/apt/lists/*

# Pacchetto Debian "3.0 (native)": dpkg-buildpackage lavora direttamente
# sull'albero sorgente (nessun tarball upstream separato), quindi copiamo
# l'intero albero necessario, incluso debian/, dentro il container.
COPY --chown=root:root CMakeLists.txt COPYRIGHT LICENSE VERSION.txt /build/orme/
COPY --chown=root:root src/     /build/orme/src/
COPY --chown=root:root qml/     /build/orme/qml/
COPY --chown=root:root assets/  /build/orme/assets/
COPY --chown=root:root images/  /build/orme/images/
COPY --chown=root:root debian/  /build/orme/debian/
# Referenziato da debian/orme.install (repo apt abilitato all'installazione)
COPY --chown=root:root packaging/repo/ /build/orme/packaging/repo/
# Referenziato da CMakeLists.txt (install(FILES packaging/linux/debian/orme.desktop ...))
COPY --chown=root:root packaging/linux/debian/orme.desktop /build/orme/packaging/linux/debian/orme.desktop

WORKDIR /build/orme
