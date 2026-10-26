# PicoDeb
An ultra-minimalist Debian-based desktop Linux engineered for instant startup, zero background distraction, and minimal footprint.

## Build

### macOS with Docker Desktop

Install and start Docker Desktop, then run this from the project directory:

```sh
make dev-build
make dev-build ARCH=x64
```

Without `ARCH`, the Docker build detects the host architecture (`arm64` on Apple Silicon, `amd64` on Intel Macs). Set `ARCH=arm64`, `ARCH=amd64`, or `ARCH=x64` to choose explicitly. The build uses a privileged container because live-build needs Linux mount capabilities; only run it for a project you trust. The source is copied into the container for building, and only the finished image is written back to `dist/`.

### Native Debian Linux

Build on a Debian Linux machine matching the target architecture:

```sh
sudo apt update
sudo apt install make live-build
make native-build
```

The native build also detects the host architecture. You can explicitly select `arm64`, `amd64`, or `x64`, but native builds require the matching machine architecture. Use `make clean` to remove generated images and `make help` to list the targets.

## Test in UTM

Create an ARM64 Linux VM using **Virtualize**, then attach `dist/agent-desktop-arm64.iso` as a CD/DVD drive and boot from it. The ISO boots the live system; it does not install Debian onto a separate virtual disk. An installer workflow is not included yet.
