#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ARCH="${1:-}"

if [[ -z "${ARCH}" ]]; then
    case "$(uname -m)" in
        arm64|aarch64)
            ARCH="arm64"
            ;;
        x86_64|amd64)
            ARCH="amd64"
            ;;
        *)
            echo "无法从主机架构 $(uname -m) 推断目标；请指定 arm64 或 amd64。" >&2
            exit 2
            ;;
    esac
fi

case "${ARCH}" in
    arm64|aarch64)
        ARCH="arm64"
        PLATFORM="linux/arm64"
        ;;
    amd64|x64|x86_64)
        ARCH="amd64"
        PLATFORM="linux/amd64"
        ;;
    *)
        echo "用法: $0 [arm64|amd64|x64]" >&2
        exit 2
        ;;
esac

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker Not Found. Please install and start Docker Desktop." >&2
    exit 1
fi

docker build \
    --platform "${PLATFORM}" \
    --tag picodeb-builder:bookworm \
    --file "${SCRIPT_DIR}/Dockerfile" \
    "${SCRIPT_DIR}"

mkdir -p "${SCRIPT_DIR}/dist"

docker run --rm --privileged \
    --platform "${PLATFORM}" \
    --volume "${SCRIPT_DIR}:/src:ro" \
    --volume "${SCRIPT_DIR}/dist:/out" \
    picodeb-builder:bookworm \
    bash -euc '
        build_dir=/tmp/picodeb-source
        mkdir -p "${build_dir}"
        cp -a /src/. "${build_dir}/"
        cd "${build_dir}"
        bash ./build.sh "$1"
        iso="${build_dir}/dist/agent-desktop-$1.iso"
        cp "${iso}" /out/
    ' _ "${ARCH}"