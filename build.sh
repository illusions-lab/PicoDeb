#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ARCH="${1:-}"
OUTPUT_DIR="${SCRIPT_DIR}/dist"

if [[ -z "${ARCH}" ]]; then
  case "$(uname -m)" in
    arm64|aarch64)
      ARCH="arm64"
      ;;
    x86_64|amd64)
      ARCH="amd64"
      ;;
    *)
      echo "Unable to infer target architecture from $(uname -m); specify arm64 or amd64." >&2
      exit 2
      ;;
  esac
fi

case "${ARCH}" in
  arm64|aarch64)
    ARCH="arm64"
    HOST_ARCH="aarch64"
    ;;
  amd64|x64|x86_64)
    ARCH="amd64"
    HOST_ARCH="x86_64"
    ;;
  *)
    echo "Usage: sudo $0 [arm64|amd64|x64]" >&2
    exit 2
    ;;
esac

OUTPUT_ISO="${OUTPUT_DIR}/agent-desktop-${ARCH}.iso"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Please run as root (e.g., sudo $0 ${ARCH})." >&2
  exit 1
fi

if [[ "$(uname -m)" != "${HOST_ARCH}" ]]; then
  echo "Target architecture ${ARCH} requires a native ${HOST_ARCH} build machine; the current host is $(uname -m)." >&2
  exit 1
fi

if ! command -v lb >/dev/null 2>&1; then
  echo "Missing live-build, please install it first: apt install live-build" >&2
  exit 1
fi

BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/picodeb-build.XXXXXX")"
cleanup() {
  rm -rf -- "${BUILD_DIR}"
}
trap cleanup EXIT

mkdir -p \
  "${OUTPUT_DIR}" \
  "${BUILD_DIR}/config/package-lists" \
  "${BUILD_DIR}/config/includes.chroot/etc/systemd/system" \
  "${BUILD_DIR}/config/hooks/live"

sed "s/^linux-image-.*$/linux-image-${ARCH}/" \
  "${SCRIPT_DIR}/configs/packages.list" \
  > "${BUILD_DIR}/config/package-lists/agent.list.chroot"
cp "${SCRIPT_DIR}/configs/agent-desktop.service" \
  "${BUILD_DIR}/config/includes.chroot/etc/systemd/system/agent-desktop.service"
cp "${SCRIPT_DIR}/configs/agent-setup.hook.chroot" \
  "${BUILD_DIR}/config/hooks/live/0100-agent-setup.hook.chroot"
chmod +x "${BUILD_DIR}/config/hooks/live/0100-agent-setup.hook.chroot"

if [[ -f "${SCRIPT_DIR}/keys/id_ed25519.pub" ]]; then
  install -D -m 0600 "${SCRIPT_DIR}/keys/id_ed25519.pub" \
    "${BUILD_DIR}/config/includes.chroot/home/agent/.ssh/authorized_keys"
fi

cd "${BUILD_DIR}"
lb config \
  --ignore-system-defaults \
  --distribution bookworm \
  --architecture "${ARCH}" \
  --binary-image iso \
  --bootloaders grub-efi \
  --debian-installer none \
  --apt-recommends false \
  --image-name agent-desktop

lb build

ISO_PATH="$(find "${BUILD_DIR}" -maxdepth 1 -type f -name '*.iso' -print -quit)"
if [[ -z "${ISO_PATH}" ]]; then
  echo "live-build completed, but no output .iso image found." >&2
  exit 1
fi

cp "${ISO_PATH}" "${OUTPUT_ISO}"
echo ">>> Build successful: ${OUTPUT_ISO}"
