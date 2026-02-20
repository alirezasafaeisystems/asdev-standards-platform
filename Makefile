.PHONY: ci lint typecheck validate-manifests test security-audit coverage build compliance-report validate-generated-reports

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

compliance-report:
	bash scripts/generate-compliance-report.sh

validate-generated-reports:
	bash scripts/validate-generated-reports.sh docs/compliance-dashboard/report.json docs/compliance-dashboard/report.csv schemas/compliance-report.schema.json
