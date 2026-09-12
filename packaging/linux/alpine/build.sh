#!/usr/bin/env bash
# Costruisce il pacchetto Alpine Linux di "Orme" dentro Docker e copia il
# risultato in packaging/out/alpine/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUT_DIR="$REPO_ROOT/packaging/out/alpine"
IMAGE_TAG="orme-alpine-builder"

mkdir -p "$OUT_DIR"

echo "== docker build (Alpine) =="
docker build -t "$IMAGE_TAG" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT"

echo "== abuild dentro il container =="
docker run --rm \
  -v "$OUT_DIR:/out" \
  "$IMAGE_TAG" \
  sh -c '
    set -e
    abuild -r
    # REPODEST di default: se ~/.local/share/abuild esiste gia (creata da
    # abuild-keygen) i pacchetti finiscono dentro, invece che in ~/packages
    # (vedi /usr/share/abuild/default.conf).
    find "$HOME/packages" "${XDG_DATA_HOME:-$HOME/.local/share}/abuild" \
      -name "*.apk" -exec cp -v {} /out/ \; 2>/dev/null || true
  '

echo "== Pacchetto/i prodotti =="
ls -lh "$OUT_DIR"
