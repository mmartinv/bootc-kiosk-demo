#! /bin/bash

set -exo pipefail

DISTRO="${DISTRO:-fedora-eln}"

CONFIG_DIR="${CONFIG_DIR:-./images}"
IMAGE_DIR="${IMAGE_DIR:-${CONFIG_DIR}/${DISTRO}/qcow2}"

if [ -z "${CONTAINER_ENGINE}" ]; then
  CONTAINER_CMD="${CONTAINER_CMD:-$(command -v podman)}"
  [ -n "${CONTAINER_CMD}" ] || CONTAINER_CMD=$(command -v docker)
  if [ -z "${CONTAINER_CMD}" ]; then
    echo "No container engine found."
    exit 1
  else
    echo "Using detected container engine: $(basename ${CONTAINER_CMD})"
  fi
else
  CONTAINER_CMD="${CONTAINER_CMD:-$(command -v ${CONTAINER_ENGINE})}"
  if [ -z "${CONTAINER_CMD}" ]; then
    echo "Container engine not found: ${CONTAINER_ENGINE}"
    exit 1
  fi
fi

OCI_RUNTIME="${OCI_RUNTIME:-crun-qemu}"
OCI_RUNTIME_CMD="${OCI_RUNTIME_CMD:-$(command -v ${OCI_RUNTIME})}"
if [ -z "${OCI_RUNTIME_CMD}" ]; then
  echo "OCI container runtime not found: ${OCI_RUNTIME}"
  exit 1
fi

sudo chown -R "${USER}" "${IMAGE_DIR}"
#podman run --runtime "${OCI_RUNTIME_CMD}" --interactive --tty --rm quay.io/containerdisks/fedora:39 ""
podman run --runtime "${OCI_RUNTIME_CMD}" --name "${DISTRO}" --interactive --tty --rm --rootfs "${IMAGE_DIR}" ""
