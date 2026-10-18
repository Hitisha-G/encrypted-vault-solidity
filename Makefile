# Local shortcuts. CI calls the same targets, so .github/workflows/ci.yml and
# this file cannot drift apart.

FORGE ?= forge
# Test verbosity; CI passes VERBOSITY=-vvv to get traces on failure.
VERBOSITY ?= -vv
# Profile used by every target that mirrors a CI job (fuzz runs, deny warnings).
CI_PROFILE ?= ci

.PHONY: help fmt fmt-check build test gas sizes clean lint-ci ci-local

help: ## List available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-12s %s\n", $$1, $$2}'

fmt: ## Rewrite Solidity with forge fmt
	$(FORGE) fmt

fmt-check: ## Fail if any Solidity file needs forge fmt (CI job step)
	$(FORGE) fmt --check

build: ## Compile contracts with the default profile
	$(FORGE) build

sizes: ## Compile and print contract sizes (CI job step)
	FOUNDRY_PROFILE=$(CI_PROFILE) $(FORGE) build --sizes

test: ## Run unit and fuzz tests with the CI profile
	FOUNDRY_PROFILE=$(CI_PROFILE) $(FORGE) test $(VERBOSITY)

gas: ## Run tests with a gas report (CI job step)
	FOUNDRY_PROFILE=$(CI_PROFILE) $(FORGE) test $(VERBOSITY) --gas-report

clean: ## Remove forge build artifacts
	$(FORGE) clean

lint-ci: ## Lint GitHub Actions workflows with actionlint (CI job step)
	actionlint

ci-local: lint-ci fmt-check sizes gas ## Reproduce the CI jobs locally
