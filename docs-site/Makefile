.PHONY: html clean deps

PYTHON ?= python3
VENV ?= .venv
VENV_PYTHON := $(VENV)/bin/python3
VENV_PIP := $(VENV)/bin/pip
REQS := requirements.txt

# Build docs in an isolated local virtualenv to avoid system package constraints.
deps:
	@test -x "$(VENV_PYTHON)" || $(PYTHON) -m venv "$(VENV)"
	@$(VENV_PYTHON) -c "import sphinx" >/dev/null 2>&1 || $(VENV_PIP) install -r $(REQS)

html: deps
	$(VENV_PYTHON) -m sphinx -b html source _build/html

clean:
	rm -rf _build
