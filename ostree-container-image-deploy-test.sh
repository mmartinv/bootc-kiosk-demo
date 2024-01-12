#! /bin/bash

set -euox pipefail

if [ "$UID" != "0" ]; then
  echo "This script must be run as root"
  exit 1
fi

IMAGE="${IMAGE:-containers-storage:quay.io/mmartinv/bootc-kiosk-demo}"
DISTRO="${DISTRO:-fedora-eln}"

TREE_DIR="${TREE_DIR:-/tmp/ostree}"

[ -z "$(ls "${TREE_DIR}/ostree/deploy/default/deploy" 2>/dev/null)" ] || chattr -i ${TREE_DIR}/ostree/deploy/default/deploy/*
rm -rf "${TREE_DIR}"
mkdir -p "${TREE_DIR}"
podman pull "${IMAGE}:${DISTRO}"
ostree admin init-fs --modern "${TREE_DIR}" --sysroot="${TREE_DIR}"
ostree admin os-init default --sysroot="${TREE_DIR}"
ostree container image deploy --imgref="ostree-unverified-image:$IMAGE:$DISTRO" \
                              --stateroot=default \
                              --target-imgref="ostree-remote-registry:${IMAGE}" \
                              --karg=rw --karg=console=tty0 --karg=console=ttyS0 \
                              --karg=root=LABEL=root \
                              --sysroot="${TREE_DIR}"
