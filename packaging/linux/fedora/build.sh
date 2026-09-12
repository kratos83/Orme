#!/usr/bin/env bash
# Build a Fedora RPM for "giochi" inside a Docker container and extract the
# resulting package(s) into packaging/out/fedora/.
#
# Usage: packaging/linux/fedora/build.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
OUT_DIR="${REPO_ROOT}/packaging/out/fedora"
IMAGE_TAG="giochi-fedora-builder"

mkdir -p "${OUT_DIR}"

echo "==> Building Fedora builder image (${IMAGE_TAG})..."
docker build -t "${IMAGE_TAG}" "${SCRIPT_DIR}"

# Read name/version straight out of the spec file so the tarball name always
# matches what the spec expects.
NAME=$(awk '/^Name:/{print $2}' "${SCRIPT_DIR}/giochi.spec")
VERSION=$(awk '/^Version:/{print $2}' "${SCRIPT_DIR}/giochi.spec")
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
        rpmbuild -ba ~/rpmbuild/SPECS/giochi.spec
        find ~/rpmbuild/RPMS ~/rpmbuild/SRPMS -name "*.rpm" -exec cp {} /rpmbuild-out/ \;
    '

echo "==> Fixing output file ownership..."
docker run --rm -v "${OUT_DIR}:/out" "${IMAGE_TAG}" chown -R "$(id -u):$(id -g)" /out

echo "==> RPM(s) produced in ${OUT_DIR}:"
ls -la "${OUT_DIR}"
