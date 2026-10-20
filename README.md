# encrypted-vault-solidity

A small Solidity vault that keeps per-user balances and secrets encrypted on-chain, built to explore confidential smart contracts with fully homomorphic encryption (FHE).

The idea: users deposit, withdraw, and transfer without revealing amounts in plaintext, while the contract still enforces balance checks over encrypted values. Access to a decrypted view is gated by explicit, revocable permissions.

## Goals

- A plain (non-encrypted) reference vault first, with full Foundry tests, so behaviour is easy to reason about
- An FHE-backed variant where balances and transfer amounts are encrypted types
- Encrypted comparisons for "sufficient balance" checks without leaking the amount
- Owner and per-user access control for viewing decrypted values
- Reentrancy-safe withdrawals and clear events for indexers

## Planned layout

```
src/
  PlainVault.sol            # reference vault with plaintext balances
  EncryptedVault.sol        # FHE variant with encrypted balances
test/                       # Foundry unit and fuzz tests
script/                     # deployment scripts for local and testnet
docs/                       # design notes and threat model
```

## Tooling (target)

- [Foundry](https://book.getfoundry.sh/) for build, test, and fuzzing
- `make ci-local` mirrors CI: `actionlint`, `forge fmt --check`, `forge build --sizes`, and `forge test --gas-report`
- CI steps call the same Makefile targets (`make lint-ci`, `make fmt-check`, `make sizes`, `make gas VERBOSITY=-vvv`), so local runs and CI cannot drift; CI adds a Foundry build cache
- Dependabot opens a weekly grouped PR to keep pinned GitHub Actions current
- Docs-only changes (`*.md`, `docs/`, `LICENSE`) skip CI; a weekly scheduled run (Mondays 03:30 UTC) catches Foundry stable releases that change `fmt` or build behaviour
- Solhint and `forge fmt` checks in CI
- Slither static analysis on every change
- Copy `.env.example` to `.env` for local RPC and deploy keys (`.env` is gitignored)

## Design

See [docs/design.md](docs/design.md) for the contract surface, invariants, and threat model.

## Status

`PlainVault` (the plaintext reference vault) is in `src/`. Its Foundry tests and the FHE-backed `EncryptedVault` land next.

## License

[MIT](LICENSE)
