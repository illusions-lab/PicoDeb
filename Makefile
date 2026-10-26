ARCH ?=
.DEFAULT_GOAL := build

.PHONY: build native-build dev-build clean help

build: native-build

native-build:
	sudo bash ./build.sh "$(ARCH)"

dev-build:
	bash ./dev-build.sh "$(ARCH)"

clean:
	rm -f dist/agent-desktop-*.img dist/agent-desktop-*.iso

help:
	@printf '%s\n' 'make                         Native build; auto-detect architecture'
	@printf '%s\n' 'make native-build ARCH=arm64 Build ARM64 natively on Debian Linux'
	@printf '%s\n' 'make dev-build               Docker build; auto-detect host architecture'
	@printf '%s\n' 'make dev-build ARCH=x64      Docker build for amd64'
	@printf '%s\n' 'make clean                   Remove generated images from dist/'