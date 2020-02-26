SHARDS_BIN ?= $(shell which shards)

build:
	$(SHARDS_BIN) build --release $(CRFLAGS)
	CLANG=clang++-5.0 BINDGEN_DYNAMIC=1 lib/bindgen/tool.sh TEMPLATE.yml
