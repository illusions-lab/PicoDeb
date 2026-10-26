FROM debian:bookworm-slim

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    case "${TARGETARCH}" in \
    arm64) grub_package=grub-efi-arm64-bin ;; \
    amd64) grub_package=grub-efi-amd64-bin ;; \
    *) echo "Unsupported Docker target architecture: ${TARGETARCH}" >&2; exit 2 ;; \
    esac; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    debootstrap \
    dosfstools \
    "${grub_package}" \
    live-build \
    mtools \
    parted \
    squashfs-tools \
    xorriso; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src