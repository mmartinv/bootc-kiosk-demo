#! /bin/bash

set -exo pipefail

DISTRO="${DISTRO:-fedora-eln}"

BLUEPRINT_FILE="/tmp/blueprint.json"
OUTPUT_DIR="./images/${DISTRO}"

IMAGE_TYPE="${IMAGE_TYPE:-qcow2}"

mkdir -p "${OUTPUT_DIR}"

if [ -z "$CONTAINER_ENGINE" ]; then
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

SSH_PUB_KEY=$(cat "${HOME}/.ssh/id_rsa.pub")
echo "{
  \"blueprint\": {
    \"customizations\": {
      \"user\": [
        {
          \"name\": \"${USER}\",
          \"password\": \"redhat\",
          \"key\": \"${SSH_PUB_KEY})\",
          \"groups\": [
            \"wheel\"
          ]
        }
      ]
    }
  }
}" > "${BLUEPRINT_FILE}"

[ "$(basename ${CONTAINER_CMD})" != "podman" ] || CONTAINER_CMD="sudo ${CONTAINER_CMD}"
[ "$(basename ${CONTAINER_CMD})" != "docker" ] || [ "$(docker context show)" != "rootless" ] || \
  (echo "Cannot use rootless docker to build images please change your docker context to be rootful" && exit 1)

${CONTAINER_CMD} run \
    --rm \
    -it \
    --privileged \
    --pull "newer" \
    --security-opt "label=type:unconfined_t" \
    -v "${OUTPUT_DIR}:/output" \
    -v "${BLUEPRINT_FILE}:/config.json" \
    "quay.io/centos-bootc/bootc-image-builder:latest" \
    --type "${IMAGE_TYPE}" \
    --config "/config.json" \
    "quay.io/mmartinv/bootc-kiosk-demo:${DISTRO}"
