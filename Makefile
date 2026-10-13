# Local shortcuts mirroring .github/workflows/ci.yml.

.PHONY: help fmt fmt-check build test gas sizes clean ci-local

help: ## List available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-12s %s\n", $$1, $$2}'

fmt: ## Rewrite Solidity with forge fmt
	forge fmt

fmt-check: ## Fail if any Solidity file needs forge fmt (same as CI)
	forge fmt --check

build: ## Compile contracts
	forge build

sizes: ## Compile and print contract sizes (same as CI)
	FOUNDRY_PROFILE=ci forge build --sizes

test: ## Run unit and fuzz tests
	FOUNDRY_PROFILE=ci forge test -vv

gas: ## Run tests with a gas report (same as CI)
	FOUNDRY_PROFILE=ci forge test --gas-report

clean: ## Remove forge build artifacts
	forge clean

ci-local: fmt-check sizes gas ## Reproduce the CI job locally
