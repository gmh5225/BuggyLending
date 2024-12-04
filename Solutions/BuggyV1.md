## The Bug

The issue exists in the `canLiquidate()` function:

```solidity
bool isDefaulted = block.timestamp + activeLoan.dueDate > activeLoan.startTime;
```

## Why This Is An Issue

1. The formula adds `block.timestamp` and `dueDate` instead of comparing them
2. Since `dueDate` is set as `block.timestamp + LOAN_DURATION` when borrowing:
   - `block.timestamp + dueDate` will ALWAYS be greater than `startTime`
   - This means `isDefaulted` will ALWAYS be `true`

## Attack Scenario

1. Borrower takes out a loan with valid collateral
2. Lender can immediately liquidate the loan
3. Borrower loses their collateral unfairly, even though they just borrowed

Example values:
- `startTime` = 1000 (current block timestamp when borrowed)
- `dueDate` = 1000 + 20 days = 1720000
- `block.timestamp` = 1000
- `block.timestamp + dueDate` = 1000 + 1720000 = 1721000
- 1721000 > 1000 is always true!

## Impact

- Lenders can liquidate ANY loan immediately after it's borrowed
- Borrowers will lose their collateral unfairly
- The 20-day loan duration becomes meaningless

## Fix

The correct logic should be:

```solidity
bool isDefaulted = block.timestamp > activeLoan.dueDate;
```

This would only allow liquidation after the actual due date has passed. 