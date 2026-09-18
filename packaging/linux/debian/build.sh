#!/usr/bin/env bash
# Costruisce il pacchetto Debian di "Orme" dentro Docker e copia il
# risultato in packaging/out/debian/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUT_DIR="$REPO_ROOT/packaging/out/debian"
IMAGE_TAG="orme-debian-builder"

mkdir -p "$OUT_DIR"

# Sincronizza debian/changelog con l'unica fonte del numero di versione
# (VERSION alla radice del repo). Se la versione e' cambiata rispetto alla
# voce piu' recente, ne aggiunge una nuova in cima (con data di oggi) invece
# di riscrivere quella vecchia: per rilasciare una nuova versione basta
# modificare VERSION, non serve piu' toccare debian/changelog a mano. Se e'
# gia' aggiornato (es. il changelog e' stato ricommittato dopo l'ultima
# build) non fa nulla, cosi' non si accumulano voci duplicate ad ogni build.
VERSION=$(cat "$REPO_ROOT/VERSION.txt")
CHANGELOG="$REPO_ROOT/debian/changelog"
CURRENT_TOP_VERSION=$(sed -n '1s/^orme (\([^)]*\)).*/\1/p' "$CHANGELOG")
if [ "$CURRENT_TOP_VERSION" != "${VERSION}-1" ]; then
  echo "== Nuova voce in debian/changelog: ${VERSION}-1 (era ${CURRENT_TOP_VERSION}) =="
  TMP_CHANGELOG=$(mktemp)
  {
    printf 'orme (%s-1) unstable; urgency=medium\n\n' "$VERSION"
    printf '  * Nuova versione: %s.\n\n' "$VERSION"
    printf ' -- Angelo Scarnà <angelo.scarna@primanotanet.it>  %s\n\n' "$(date -R)"
    cat "$CHANGELOG"
  } > "$TMP_CHANGELOG"
  mv "$TMP_CHANGELOG" "$CHANGELOG"
fi

echo "== docker build (Debian) =="
docker build -t "$IMAGE_TAG" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT"

echo "== dpkg-buildpackage dentro il container =="
# Il container builda come root: a differenza di arch/alpine (makepkg/abuild
# rifiutano di girare come root), dpkg-buildpackage non ha questa
# restrizione, quindi non serve un utente non privilegiato ne' il chmod
# della cartella di output per il mount.
docker run --rm \
  -v "$OUT_DIR:/out" \
  "$IMAGE_TAG" \
  bash -c 'dpkg-buildpackage -us -uc -b && cp -v ../orme*.deb /out/'

echo "== Pacchetto/i prodotti =="
ls -lh "$OUT_DIR"
