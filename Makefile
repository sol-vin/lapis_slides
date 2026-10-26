.PHONY: build serve validate spec clean

SUNSTONE ?= sunstone
CRYSTAL ?= crystal

build:
	$(SUNSTONE) build -o .

serve:
	$(SUNSTONE) serve

validate:
	$(SUNSTONE) validate

spec:
	$(CRYSTAL) spec

clean:
	rm -rf dist/ bin/
