.PHONY: all install deps release debug

all: release
install: install-release

RIME_BIN_DIR = librime/dist/bin
RIME_LIB_DIR = librime/dist/lib
DERIVED_DATA_PATH = build

RIME_LIBRARY_FILE_NAME = librime.1.dylib
RIME_LIBRARY = lib/$(RIME_LIBRARY_FILE_NAME)

ifndef BOOST_ROOT
BOOST_ROOT := $(shell brew --prefix boost 2>/dev/null)
endif
export BOOST_ROOT

RIME_DEPS = librime/lib/libmarisa.a \
	librime/lib/libleveldb.a \
	librime/lib/libopencc.a \
	librime/lib/libyaml-cpp.a
PLUM_DATA = bin/rime-install \
	data/plum/default.yaml \
	data/plum/symbols.yaml \
	data/plum/essay.txt
PLUM_PLACEHOLDER_DATA = \
	data/plum/pinyin.yaml \
	data/plum/zhuyin.yaml \
	data/plum/bopomofo_express.schema.yaml \
	data/plum/bopomofo_tw.schema.yaml \
	data/plum/bopomofo.schema.yaml \
	data/plum/cangjie5_express.schema.yaml \
	data/plum/cangjie5.dict.yaml \
	data/plum/cangjie5.schema.yaml \
	data/plum/stroke.dict.yaml \
	data/plum/stroke.schema.yaml \
	data/plum/terra_pinyin.dict.yaml \
	data/plum/terra_pinyin.schema.yaml \
	data/plum/detenele.schema.yaml \
	data/plum/terra_pinyin_12345.schema.yaml \
	data/plum/key_bindings.yaml \
	data/plum/punctuation.yaml \
	data/plum/default.yaml \
	data/plum/essay.txt \
	data/plum/luna_pinyin_fluency.schema.yaml \
	data/plum/luna_pinyin_simp.schema.yaml \
	data/plum/luna_pinyin_tw.schema.yaml \
	data/plum/luna_pinyin.dict.yaml \
	data/plum/luna_pinyin.schema.yaml \
	data/plum/luna_quanpin.schema.yaml \
	data/plum/symbols.yaml
OPENCC_DATA = data/opencc/TSCharacters.ocd2 \
	data/opencc/TSPhrases.ocd2 \
	data/opencc/t2s.json
SPARKLE_FRAMEWORK = Frameworks/Sparkle.framework
PACKAGE = package/Squirrel.pkg
DEPS_CHECK = $(RIME_LIBRARY) $(PLUM_DATA) $(OPENCC_DATA) $(SPARKLE_FRAMEWORK)

OPENCC_DATA_OUTPUT = librime/share/opencc/*.*
PLUM_DATA_OUTPUT = plum/output/*.*
PLUM_OPENCC_OUTPUT = plum/output/opencc/*.*
RIME_PACKAGE_INSTALLER = plum/rime-install

INSTALL_NAME_TOOL = $(shell xcrun -find install_name_tool)
INSTALL_NAME_TOOL_ARGS = -add_rpath @loader_path/../Frameworks

.PHONY: librime copy-rime-binaries

$(RIME_LIBRARY):
	$(MAKE) librime

$(RIME_DEPS):
	$(MAKE) -C librime deps

librime: $(RIME_DEPS)
	$(MAKE) -C librime release install
	$(MAKE) copy-rime-binaries

copy-rime-binaries:
	cp -L $(RIME_LIB_DIR)/$(RIME_LIBRARY_FILE_NAME) lib/
	cp -pR $(RIME_LIB_DIR)/rime-plugins lib/
	cp $(RIME_BIN_DIR)/rime_deployer bin/
	cp $(RIME_BIN_DIR)/rime_dict_manager bin/
	$(INSTALL_NAME_TOOL) $(INSTALL_NAME_TOOL_ARGS) bin/rime_deployer
	$(INSTALL_NAME_TOOL) $(INSTALL_NAME_TOOL_ARGS) bin/rime_dict_manager

.PHONY: data plum-data opencc-data copy-plum-data copy-opencc-data

data: plum-data opencc-data

$(PLUM_DATA):
	$(MAKE) plum-data

$(OPENCC_DATA):
	$(MAKE) opencc-data

plum-data:
	mkdir -p data/plum bin
	cp $(RIME_PACKAGE_INSTALLER) bin/
	touch $(PLUM_PLACEHOLDER_DATA)

opencc-data:
	$(MAKE) -C librime deps/opencc
	$(MAKE) copy-opencc-data

copy-plum-data:
	mkdir -p data/plum
	cp $(PLUM_DATA_OUTPUT) data/plum/
	cp $(RIME_PACKAGE_INSTALLER) bin/

copy-opencc-data:
	mkdir -p data/opencc
	cp $(OPENCC_DATA_OUTPUT) data/opencc/
	cp $(PLUM_OPENCC_OUTPUT) data/opencc/ > /dev/null 2>&1 || true

deps: librime data

ifdef ARCHS
BUILD_SETTINGS += ARCHS="$(ARCHS)"
BUILD_SETTINGS += ONLY_ACTIVE_ARCH=NO
_=$() $()
export CMAKE_OSX_ARCHITECTURES = $(subst $(_),;,$(ARCHS))
endif

ifdef MACOSX_DEPLOYMENT_TARGET
BUILD_SETTINGS += MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)"
endif

BUILD_SETTINGS += COMPILER_INDEX_STORE_ENABLE=YES

release: $(DEPS_CHECK)
	mkdir -p $(DERIVED_DATA_PATH)
	bash package/add_data_files
	xcodebuild -project Squirrel.xcodeproj -configuration Release -scheme Squirrel -derivedDataPath $(DERIVED_DATA_PATH) $(BUILD_SETTINGS) build
	bash package/copy_wusong_data "$(DERIVED_DATA_PATH)/Build/Products/Release/Squirrel.app"

debug: $(DEPS_CHECK)
	mkdir -p $(DERIVED_DATA_PATH)
	bash package/add_data_files
	xcodebuild -project Squirrel.xcodeproj -configuration Debug -scheme Squirrel -derivedDataPath $(DERIVED_DATA_PATH)  $(BUILD_SETTINGS) build
	bash package/copy_wusong_data "$(DERIVED_DATA_PATH)/Build/Products/Debug/Squirrel.app"

.PHONY: sparkle copy-sparkle-framework

$(SPARKLE_FRAMEWORK):
	git submodule update --init --recursive Sparkle
	$(MAKE) sparkle

sparkle:
	xcodebuild -project Sparkle/Sparkle.xcodeproj -configuration Release $(BUILD_SETTINGS) build
	$(MAKE) copy-sparkle-framework

package/generate_keys:
	xcodebuild -project Sparkle/Sparkle.xcodeproj -scheme generate_keys -configuration Release -derivedDataPath Sparkle/build $(BUILD_SETTINGS) build
	cp Sparkle/build/Build/Products/Release/generate_keys package/

package/sign_update:
	xcodebuild -project Sparkle/Sparkle.xcodeproj -scheme sign_update -configuration Release -derivedDataPath Sparkle/build $(BUILD_SETTINGS) build
	cp Sparkle/build/Build/Products/Release/sign_update package/

copy-sparkle-framework:
	mkdir -p Frameworks
	cp -RP Sparkle/build/Release/Sparkle.framework Frameworks/

clean-sparkle:
	rm -rf Frameworks/* > /dev/null 2>&1 || true
	rm -rf Sparkle/build > /dev/null 2>&1 || true

.PHONY: package archive force-package

force-package:

$(PACKAGE): force-package
ifdef DEV_ID
	bash package/sign_app "$(DEV_ID)" "$(DERIVED_DATA_PATH)"
endif
	bash package/make_package "$(DERIVED_DATA_PATH)"
ifdef DEV_ID
	productsign --sign "Developer ID Installer: $(DEV_ID)" package/Squirrel.pkg package/Squirrel-signed.pkg
	rm package/Squirrel.pkg
	mv package/Squirrel-signed.pkg package/Squirrel.pkg
	xcrun notarytool submit package/Squirrel.pkg --keychain-profile "$(DEV_ID)" --wait
	xcrun stapler staple package/Squirrel.pkg
endif

package: release $(PACKAGE)

archive: package package/sign_update
	bash package/make_archive

DSTROOT = /Library/Input Methods
SQUIRREL_APP_ROOT = $(DSTROOT)/Squirrel.app

.PHONY: permission-check install-debug install-release

permission-check:
	[ -d "$(DSTROOT)" ] || sudo mkdir -p "$(DSTROOT)"

install-debug: debug permission-check
	sudo rm -rf "$(SQUIRREL_APP_ROOT)"
	sudo cp -R $(DERIVED_DATA_PATH)/Build/Products/Debug/Squirrel.app "$(DSTROOT)"
	sudo chown -R root:wheel "$(SQUIRREL_APP_ROOT)"
	sudo DSTROOT="$(DSTROOT)" RIME_NO_PREBUILD=1 bash scripts/postinstall

install-release: release permission-check
	sudo rm -rf "$(SQUIRREL_APP_ROOT)"
	sudo cp -R $(DERIVED_DATA_PATH)/Build/Products/Release/Squirrel.app "$(DSTROOT)"
	sudo chown -R root:wheel "$(SQUIRREL_APP_ROOT)"
	sudo DSTROOT="$(DSTROOT)" bash scripts/postinstall

.PHONY: clean clean-deps

clean:
	rm -rf build > /dev/null 2>&1 || true
	rm build.log > /dev/null 2>&1 || true
	rm bin/* > /dev/null 2>&1 || true
	rm lib/* > /dev/null 2>&1 || true
	rm lib/rime-plugins/* > /dev/null 2>&1 || true
	rm data/plum/* > /dev/null 2>&1 || true
	rm data/opencc/* > /dev/null 2>&1 || true

clean-package:
	rm -rf package/*appcast.xml > /dev/null 2>&1 || true
	rm -rf package/*.pkg > /dev/null 2>&1 || true
	rm -rf package/sign_update > /dev/null 2>&1 || true

clean-deps:
	$(MAKE) -C plum clean
	$(MAKE) -C librime clean
	rm -rf librime/dist > /dev/null 2>&1 || true
	$(MAKE) clean-sparkle
