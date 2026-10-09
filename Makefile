.PHONY: build serve validate clean casts

SUNSTONE ?= sunstone
CRYSTAL ?= crystal

build:
	$(SUNSTONE) build -o .

serve:
	$(SUNSTONE) serve

validate:
	$(SUNSTONE) validate

casts:
	$(CRYSTAL) run scripts/record_casts.cr -- --all

clean:
	rm -rf dist/ bin/
