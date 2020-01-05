CRYSTAL_BIN ?= $(shell which crystal)
SHARDS_BIN ?= $(shell which shards)

build:
	$(SHARDS_BIN) build --release $(CRFLAGS)
test: build
	$(CRYSTAL_BIN) spec --verbose
