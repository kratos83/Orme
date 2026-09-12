# Ambiente di build per il pacchetto Alpine Linux di "Orme" (eseguibile: giochi)
#
# I pacchetti Qt6 non sono nei repository stabili di Alpine: sono disponibili
# solo su alpine:edge, nel repo "community" (verificato dentro il container
# con `apk search qt6` e `apk policy <pacchetto>`):
#   qt6-qtbase-dev, qt6-qtdeclarative-dev, qt6-qtmultimedia-dev  -> edge/community
#   qt6-qtmultimedia-ffmpeg (backend runtime per i suoni)        -> edge/community
# cmake, alpine-sdk, build-base                                  -> edge/main
#
# abuild non permette di girare come root: serve un utente normale nel
# gruppo "abuild", con una chiave di firma generata da abuild-keygen e sudo
# senza password (necessario perché abuild-keygen installa la chiave
# pubblica in /etc/apk/keys tramite sudo).
FROM alpine:edge

RUN apk update && apk add --no-cache \
        alpine-sdk \
        build-base \
        sudo \
        cmake \
        samurai \
        qt6-qtbase-dev \
        qt6-qtdeclarative-dev \
        qt6-qtmultimedia-dev \
        qt6-qtmultimedia-ffmpeg

RUN adduser -D builder && \
    addgroup builder abuild && \
    echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder && \
    chmod 440 /etc/sudoers.d/builder

# Sorgenti del progetto copiate esplicitamente (niente .git, build/, packaging/)
COPY --chown=builder:builder CMakeLists.txt COPYRIGHT LICENSE /home/builder/orme-source/
COPY --chown=builder:builder src/    /home/builder/orme-source/src/
COPY --chown=builder:builder qml/    /home/builder/orme-source/qml/
COPY --chown=builder:builder assets/ /home/builder/orme-source/assets/

COPY --chown=builder:builder packaging/linux/alpine/APKBUILD /home/builder/build/APKBUILD

USER builder
WORKDIR /home/builder/build

# Chiave di firma abuild: generata e installata in /etc/apk/keys (via sudo)
RUN abuild-keygen -a -i -n
