#! /bin/bash

set -euxo pipefail

declare -A BASE_IMAGE

BASE_IMAGE['fedora-eln']="quay.io/mmartinv/bootc-kiosk-demo:fedora-eln"
BASE_IMAGE['centos-stream9']="quay.io/mmartinv/bootc-kiosk-demo:centos-stream9"

DISTRO="${DISTRO:-fedora-eln}"
TAG="${TAG:-${BASE_IMAGE[$DISTRO]}}"

podman build --pull="newer" --build-arg="BASE_IMAGE=${BASE_IMAGE[${DISTRO}]}" --tag="${TAG}" --file="Containerfile.flatpak" .
