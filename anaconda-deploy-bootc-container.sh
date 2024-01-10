#! /bin/bash

set -euxo pipefail

declare -A LOCATION

LOCATION["fedora-eln"]="https://odcs.fedoraproject.org/composes/production/latest-Fedora-ELN/compose/BaseOS/x86_64/os"
#LOCATION["centos-stream9"]="http://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os"
LOCATION["centos-stream9"]=${LOCATION["fedora-eln"]}

DISTRO="${DISTRO:-fedora-eln}"
IMAGE="quay.io/mmartinv/bootc-kiosk-demo:$DISTRO"

SSH_PUB_KEY=$(cat "${HOME}/.ssh/id_rsa.pub")

KICKSTART_FILE="/tmp/anaconda-ks.cfg"
echo "
text

# Basic partitioning
clearpart --all --initlabel --disklabel=gpt

part prepboot  --size=4    --fstype=prepboot
part biosboot  --size=1    --fstype=biosboot
part /boot/efi --size=100  --fstype=efi
part /boot     --size=1000 --fstype=ext4 --label=boot
part /         --grow      --fstype xfs

#ostreecontainer --url quay.io/centos-bootc/centos-bootc:stream9 --no-signature-verification
#ostreecontainer --url quay.io/centos-bootc/centos-bootc-dev:stream9 --no-signature-verification
#ostreecontainer --url quay.io/centos-bootc/centos-bootc-cloud:stream9 --no-signature-verification
#ostreecontainer --url quay.io/centos-bootc/fedora-bootc:eln --no-signature-verification
#ostreecontainer --url quay.io/centos-bootc/fedora-bootc-dev:eln --no-signature-verification
#ostreecontainer --url quay.io/centos-bootc/fedora-bootc-cloud:eln --no-signature-verification
ostreecontainer --url ${IMAGE} --no-signature-verification

# we can inject the ssh key for the root account in the container but we can't
# get rid of this line unfortunately
rootpw redhat
sshkey --username root '${SSH_PUB_KEY}'

user --name=${USER} --groups=wheel --password=redhat --plaintext
sshkey --username ${USER} '${SSH_PUB_KEY}'
reboot

# Workarounds until https://github.com/rhinstaller/anaconda/pull/5298/ lands
#bootloader --location=none --disabled
%post --erroronfail
set -euo pipefail
# Work around anaconda wanting a root password
#passwd -l root
#rootdevice=\$(findmnt -nv -o SOURCE /)
#device=\$(lsblk -n -o PKNAME \${rootdevice})
#/usr/bin/bootupctl backend install --auto --with-static-configs --device /dev/\${device} /

# anaconda will set multi-user.target by default and won't honor what we've set in the Container
# https://github.com/rhinstaller/anaconda/blob/ee0b61fa135ba555f29bc6e3d035fbca8bcc14d5/pyanaconda/modules/services/installation.py#L174-L241
systemctl set-default graphical.target
%end
"  > "${KICKSTART_FILE}"

virt-install --connect qemu:///system  \
  --vcpus 4 --memory 3072 \
  --boot uefi,loader.secure=false \
  --network network=default,model=virtio \
  --disk size=10 --noautoconsole \
  --os-variant "${DISTRO}" --location "${LOCATION[${DISTRO}]}" \
  --initrd-inject "${KICKSTART_FILE}" --extra-args="inst.ks=file:/$(basename ${KICKSTART_FILE}) console=tty0 console=ttyS0,115200" \
  --name "kiosk-demo-${DISTRO}"
