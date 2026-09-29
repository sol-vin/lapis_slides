.PHONY: build serve validate clean

CRYSTAL ?= crystal

build:
	$(CRYSTAL) run src/builder.cr -- build

serve:
	$(CRYSTAL) run src/builder.cr -- serve

validate:
	$(CRYSTAL) run src/builder.cr -- validate

clean:
	rm -rf bin/
