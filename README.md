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
- CI runs `forge fmt --check`, `forge build --sizes`, `forge test`, and a gas report (Foundry build cache enabled)
- Solhint and `forge fmt` checks in CI
- Slither static analysis on every change

## Design

See [docs/design.md](docs/design.md) for the contract surface, invariants, and threat model.

## Status

Early scaffold. Contracts and tests land incrementally.

## License

[MIT](LICENSE)
