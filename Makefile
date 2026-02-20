.PHONY: ci lint typecheck validate-manifests test security-audit coverage build

ci: lint typecheck validate-manifests test security-audit coverage build

lint:
	bash scripts/lint.sh

typecheck:
	bash scripts/typecheck.sh

validate-manifests:
	bash scripts/validate-manifests.sh

test:
	bash scripts/test.sh

security-audit:
	bash scripts/security-audit.sh

coverage:
	bash scripts/coverage.sh

build:
	bash scripts/build.sh
