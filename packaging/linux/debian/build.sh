#!/usr/bin/env bash
# Costruisce il pacchetto Debian di "Orme" dentro Docker e copia il
# risultato in packaging/out/debian/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUT_DIR="$REPO_ROOT/packaging/out/debian"
IMAGE_TAG="orme-debian-builder"

mkdir -p "$OUT_DIR"

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
  bash -c 'dpkg-buildpackage -us -uc -b && cp -v ../orme*.deb ../orme*.buildinfo ../orme*.changes /out/'

echo "== Pacchetto/i prodotti =="
ls -lh "$OUT_DIR"
