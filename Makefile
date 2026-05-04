.PHONY: prepare debug package package-universal

ARCHS ?= arm64
BUILD_UNIVERSAL ?= 0

prepare:
	./scripts/bootstrap_sources.sh

debug:
	@test -f squirrel/Makefile || (echo "请先执行 make prepare" && exit 1)
	$(MAKE) -C squirrel debug ARCHS="$(ARCHS)"

package:
	@test -f squirrel/Makefile || (echo "请先执行 make prepare" && exit 1)
	$(MAKE) -C squirrel package ARCHS="$(ARCHS)" BUILD_UNIVERSAL="$(BUILD_UNIVERSAL)"

package-universal:
	@test -f squirrel/Makefile || (echo "请先执行 make prepare" && exit 1)
	$(MAKE) -C squirrel package ARCHS='arm64 x86_64' BUILD_UNIVERSAL=1
