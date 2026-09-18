# Ambiente di build per il pacchetto Arch Linux di "Orme" (eseguibile: giochi)
#
# Nomi pacchetto verificati dentro il container con:
#   pacman -Ss qt6
#   pacman -Si qt6-multimedia   (per i Depends effettivi, incluso qt6-multimedia-backend)
#
# makepkg NON permette di girare come root: serve un utente normale con sudo
# (senza password, limitato a pacman) per l'eventuale --syncdeps di makepkg.
FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
        base-devel \
        cmake \
        qt6-base \
        qt6-declarative \
        qt6-multimedia \
        qt6-multimedia-ffmpeg \
        sudo \
    && pacman -Scc --noconfirm

# Utente di build non privilegiato richiesto da makepkg
RUN useradd -m -G wheel -s /bin/bash builder && \
    echo 'builder ALL=(ALL) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder && \
    chmod 440 /etc/sudoers.d/builder

# Sorgenti del progetto copiate esplicitamente (niente .git, build/, packaging/):
# così il contesto di build Docker resta la root del repo senza bisogno di un
# .dockerignore fuori da packaging/.
COPY --chown=builder:builder CMakeLists.txt COPYRIGHT LICENSE VERSION /home/builder/orme-source/
COPY --chown=builder:builder src/    /home/builder/orme-source/src/
COPY --chown=builder:builder qml/    /home/builder/orme-source/qml/
COPY --chown=builder:builder assets/ /home/builder/orme-source/assets/
COPY --chown=builder:builder images/ /home/builder/orme-source/images/
# Referenziato da CMakeLists.txt (install(FILES packaging/linux/debian/orme.desktop ...))
COPY --chown=builder:builder packaging/linux/debian/orme.desktop /home/builder/orme-source/packaging/linux/debian/orme.desktop

COPY --chown=builder:builder packaging/linux/arch/PKGBUILD /home/builder/build/PKGBUILD

USER builder
WORKDIR /home/builder/build
