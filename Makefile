.PHONY: prepare debug package

prepare:
	./scripts/bootstrap_sources.sh

debug:
	@test -f squirrel/Makefile || (echo "请先执行 make prepare" && exit 1)
	$(MAKE) -C squirrel debug ARCHS='arm64'

package:
	@test -f squirrel/Makefile || (echo "请先执行 make prepare" && exit 1)
	$(MAKE) -C squirrel package ARCHS='arm64 x86_64' BUILD_UNIVERSAL=1
