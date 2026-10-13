# Design notes and threat model

This document captures the intended behaviour of the vault before any contract code lands, so the plain and encrypted variants can be checked against the same spec.

## Contracts

### PlainVault (reference)

Plaintext balances held in `mapping(address => uint256)`. Exists to pin down semantics and give the test suite a baseline that is easy to reason about.

| Function | Behaviour |
| --- | --- |
| `deposit()` | Payable. Credits `msg.value` to the caller. Reverts on zero value. |
| `withdraw(uint256 amount)` | Debits the caller, then sends ETH. Reverts if balance is insufficient. |
| `transfer(address to, uint256 amount)` | Moves balance between accounts inside the vault. No ETH leaves the contract. |
| `balanceOf(address user)` | Returns the plaintext balance. |

### EncryptedVault (FHE variant)

Same surface, but balances and amounts are encrypted integers (`euint64`). Key differences from the reference:

- **No reverting on insufficient balance.** A revert would leak whether the encrypted balance was large enough. Instead the contract computes `ok = amount <= balance` as an encrypted boolean and uses an encrypted select so the transfer moves either `amount` or `0`. The caller learns the outcome only by decrypting their own balance.
- **Inputs arrive as ciphertexts with a proof** that the sender knows the plaintext, so one user cannot replay another user's ciphertext as their own amount.
- **Reads are permissioned.** `balanceOf` returns a handle, not a value. Only the account owner, and anyone they explicitly grant, may request decryption.
- **Deposits and withdrawals of native ETH stay public** at the boundary, since `msg.value` and outgoing transfers are visible on-chain anyway. Confidentiality applies to internal balances and vault-to-vault transfers.

## Invariants

These hold for both variants and are the basis for fuzz and invariant tests:

1. The sum of all user balances equals the vault's ETH balance (plain variant checked directly; encrypted variant checked via a test-only decrypt helper).
2. A transfer never changes the total supply held in the vault.
3. A user's balance can only decrease through their own `withdraw` or `transfer` call.
4. Withdrawals cannot be re-entered to drain more than the caller's balance.

## Threat model

| Threat | Mitigation |
| --- | --- |
| Reentrancy on `withdraw` | Checks-effects-interactions ordering plus a reentrancy guard. Balance is debited before the external call. |
| Balance leak via revert or gas differences | Encrypted variant uses encrypted select instead of branching, so success and failure follow the same code path. |
| Ciphertext replay or theft | Encrypted inputs are bound to the sender with an input proof. |
| Over-broad decryption access | Access is per-handle and granted explicitly by the owner. Grants can be revoked, and new handles produced by later writes are not covered by old grants. |
| Amount inference from public events | Events emit addresses and ciphertext handles only, never plaintext amounts, for internal transfers. |
| Owner or admin abuse | The vault has no admin withdrawal path. Owner powers are limited to pausing deposits in an emergency. |

### Out of scope

- Hiding *who* transacts with whom. Sender and recipient addresses are public.
- Hiding native ETH deposit and withdrawal amounts at the vault boundary.
- Security of the underlying FHE coprocessor and key management, which is assumed to be honest.

## Testing plan

- Unit tests per function for both variants, sharing scenarios where possible.
- Fuzz tests over amounts and actor sets for invariants 1 through 3.
- A malicious receiver contract to exercise invariant 4.
- Slither on every change in CI.
