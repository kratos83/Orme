#!/usr/bin/env bash
# Build an openSUSE Tumbleweed RPM for "giochi" inside a Docker container and
# extract the resulting package(s) into packaging/out/opensuse/.
#
# Usage: packaging/linux/opensuse/build.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
OUT_DIR="${REPO_ROOT}/packaging/out/opensuse"
IMAGE_TAG="giochi-opensuse-builder"

mkdir -p "${OUT_DIR}"

echo "==> Building openSUSE Tumbleweed builder image (${IMAGE_TAG})..."
docker build -t "${IMAGE_TAG}" "${SCRIPT_DIR}"

# Sincronizza lo spec con l'unica fonte del numero di versione (VERSION alla
# radice del repo), cosi' non va mai piu' modificato a mano qui.
VERSION=$(cat "${REPO_ROOT}/VERSION")
sed -i "s/^Version:.*/Version:        ${VERSION}/" "${SCRIPT_DIR}/giochi.spec"

NAME=$(awk '/^Name:/{print $2}' "${SCRIPT_DIR}/giochi.spec")
TARBALL="${NAME}-${VERSION}.tar.gz"

echo "==> Packaging source tree as ${TARBALL}..."
WORKDIR=$(mktemp -d)
trap 'rm -rf "${WORKDIR}"' EXIT

git -C "${REPO_ROOT}" archive --format=tar --prefix="${NAME}-${VERSION}/" HEAD \
    | (mkdir -p "${WORKDIR}/src" && tar -x -C "${WORKDIR}/src")
tar -czf "${WORKDIR}/${TARBALL}" -C "${WORKDIR}/src" "${NAME}-${VERSION}"

echo "==> Running rpmbuild inside container..."
docker run --rm \
    -v "${WORKDIR}/${TARBALL}:/rpmbuild-in/${TARBALL}:ro" \
    -v "${SCRIPT_DIR}/giochi.spec:/rpmbuild-in/giochi.spec:ro" \
    -v "${OUT_DIR}:/rpmbuild-out" \
    "${IMAGE_TAG}" \
    bash -c '
        set -euo pipefail
        cp /rpmbuild-in/giochi.spec ~/rpmbuild/SPECS/
        cp "/rpmbuild-in/'"${TARBALL}"'" ~/rpmbuild/SOURCES/
        rpmbuild -bb ~/rpmbuild/SPECS/giochi.spec
        find ~/rpmbuild/RPMS -name "*.rpm" -exec cp {} /rpmbuild-out/ \;
    '

echo "==> Fixing output file ownership..."
docker run --rm -v "${OUT_DIR}:/out" "${IMAGE_TAG}" chown -R "$(id -u):$(id -g)" /out

echo "==> RPM(s) produced in ${OUT_DIR}:"
ls -la "${OUT_DIR}"
