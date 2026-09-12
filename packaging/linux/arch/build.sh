#!/usr/bin/env bash
# Costruisce il pacchetto Arch Linux di "Orme" dentro Docker e copia il
# risultato in packaging/out/arch/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUT_DIR="$REPO_ROOT/packaging/out/arch"
IMAGE_TAG="orme-arch-builder"

mkdir -p "$OUT_DIR"
# Scrivibile da qualsiasi UID: il container builda come utente non-root
# "builder", il cui UID non corrisponde a quello che possiede OUT_DIR
# sull'host (es. il runner CI), altrimenti il cp finale fallisce con
# "Permission denied".
chmod 777 "$OUT_DIR"

echo "== docker build (Arch) =="
docker build -t "$IMAGE_TAG" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT"

echo "== makepkg dentro il container =="
docker run --rm \
  -v "$OUT_DIR:/out" \
  "$IMAGE_TAG" \
  bash -c 'makepkg --noconfirm --syncdeps --cleanbuild && cp -v ./*.pkg.tar.zst /out/'

echo "== Pacchetto/i prodotti =="
ls -lh "$OUT_DIR"
