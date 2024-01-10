#! /bin/bash

set -euxo pipefail

declare -A BASE_IMAGE

BASE_IMAGE['fedora-eln']="quay.io/centos-bootc/fedora-bootc-dev:eln"
BASE_IMAGE['centos-stream9']="quay.io/centos-bootc/centos-bootc-dev:stream9"

DISTRO="${DISTRO:-fedora-eln}"
IMAGE="${IMAGE:-quay.io/mmartinv/bootc-kiosk-demo:${DISTRO}}"

podman build --pull="newer" --build-arg="BASE_IMAGE=${BASE_IMAGE[${DISTRO}]}" --tag="${IMAGE}" --file="Containerfile" .
podman push "${IMAGE}"
