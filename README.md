markdown
# MultisigVault

A multi-signature wallet contract. Requires a minimum number of owner confirmations before executing a transaction.

## State

- `owners` – list of addresses that control the vault.
- `required` – number of confirmations needed to execute a transaction.
- `transactions` – array of proposed transfers with target, value, data, execution flag, and confirmation count.
- `isConfirmed[txIndex][owner]` – tracks which owner confirmed which transaction.

## Functions

`receive()` external payable  
Emits `Deposit` and adds funds to the vault.

`submitTransaction(address to, uint256 value, bytes calldata data)`  
Only owners. Creates a new transaction and emits `SubmitTransaction`.

`confirmTransaction(uint256 txIndex)`  
Only owners. Confirms an existing transaction that is not yet executed and not already confirmed by the caller. Increments confirmation count and emits `ConfirmTransaction`.

`executeTransaction(uint256 txIndex)`  
Only owners. Requires enough confirmations (`numConfirmations >= required`). Marks transaction as executed (Checks-Effects-Interactions) then forwards the call. Emits `ExecuteTransaction` on success. Reverts if the external call fails.

## Events

`Deposit(address sender, uint256 amount, uint256 balance)`  
`SubmitTransaction(address owner, uint256 txIndex, address to, uint256 value, bytes data)`  
`ConfirmTransaction(address owner, uint256 txIndex)`  
`ExecuteTransaction(address owner, uint256 txIndex)`

## Modifiers

`onlyOwner`, `txExists`, `notExecuted`, `notConfirmed`. All self-explanatory.

## Test

The included test file (`MultisigVaultTest.sol`) covers:

- Depositing ETH.
- Full workflow: submit → two confirmations → execute → balance check.
- Reverting when a non-owner tries to submit.

Run with:
forge test

text

## Deployment

Using Foundry:
forge build
forge create --rpc-url 
R
P
C
−
−
p
r
i
v
a
t
e
−
k
e
y
RPC−−private−keyPK src/MultisigVault.sol:MultisigVault --constructor-args "[0xOwner1,0xOwner2,0xOwner3]" 2

text

## Limitations / notes

- No way to revoke a confirmation (can be added if needed).
- `executeTransaction` does not return the call result; it only checks `success` boolean. Reverts on failure.
- All owners have equal power. No weighted votes.
- Transaction order matters: transactions are stored in an array and never deleted (only marked executed). Grows indefinitely.

Useful for shared treasuries, DAO-like setups, or any group requiring approval thresholds.
