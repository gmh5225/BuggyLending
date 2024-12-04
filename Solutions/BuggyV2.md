## The Bug

The issue exists in the `commitCollateral()` function that allows borrowers to modify their collateral after loan creation:

```solidity
function commitCollateral(uint256 amount) external onlyBorrower {
    // ...
    // Overwrites existing collateral with new amount
    activeLoan.collateralAmount = amount;
    // ...
}
```

## Why This Is An Issue

1. Borrowers can modify their collateral amount at any time
2. Setting collateral to zero makes loans impossible to liquidate due to this check:
```solidity
require(activeLoan.collateralAmount > 0, "collateralAmount > 0");
```

## Attack Scenario

1. Borrower takes out a loan with valid collateral (e.g., 1000 DAI)
2. Price drops or loan defaults, making the position eligible for liquidation
3. Borrower calls `commitCollateral(0)` to set their collateral to zero
4. Liquidation becomes impossible because `activeLoan.collateralAmount > 0` check fails
5. Borrower effectively keeps the loan without risk of liquidation

## Impact

- Borrowers can avoid liquidation at will
- Lenders cannot recover their funds even when loans default
- The entire lending protocol becomes unusable

## Fix

Add validation to prevent setting insufficient collateral:

```solidity
function commitCollateral(uint256 amount) external onlyBorrower {
    require(activeLoan.isActive, "Loan not active");

    uint256 collateralValue = amount * DAI_PRICE;
    uint256 requiredCollateral = activeLoan.loanAmount * LIQUIDATION_THRESHOLD / 100;
    collateralValue = collateralValue/1e18;
    
    require(collateralValue > requiredCollateral, "Insufficient collateral");

    // ... rest of the function
}
```