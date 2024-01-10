ARG BASE_IMAGE="quay.io/centos-bootc/fedora-bootc-dev:eln"
FROM ${BASE_IMAGE}
RUN dnf -y install gdm firefox gnome-kiosk-script-session && dnf clean all
COPY files/rootfs/ /
RUN systemctl enable sshd \
    && systemctl set-default graphical.target
RUN --mount=type=tmpfs,destination=/var ostree container commit
