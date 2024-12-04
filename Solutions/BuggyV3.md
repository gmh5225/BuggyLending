## The Bug

The issue exists in the `repayLoan()` function where collateral tokens are lost:

```solidity
function repayLoan(uint256 loanId) external payable onlyBorrower nonReentrant {
    // ...
    uint256 collateralToReturn = loans[loanId].collateralAmount;
    
    delete loans[loanId];  // Bug: Deleting too early!
    lenderBalance += msg.value;

    IERC20(DAI).safeTransfer(loans[loanId].borrower, collateralToReturn);
    // ...
}
```

## Why This Is An Issue

1. The function deletes loan data before completing the collateral transfer
2. When `delete loans[loanId]` executes:
   - `loans[loanId].borrower` becomes `address(0)`
   - All other loan data is cleared
3. The collateral transfer then sends tokens to `address(0)`

## Attack Scenario

1. Borrower attempts to repay their loan
2. Contract deletes loan data prematurely
3. Collateral tokens are sent to `address(0)`
4. Tokens are permanently lost with no way to recover them

## Impact

- Borrowers lose their collateral permanently
- Tokens sent to `address(0)` can never be recovered
- Protocol loses user funds due to implementation error

## Fix

Move the `delete` operation to after the transfer:

```solidity
function repayLoan(uint256 loanId) external payable onlyBorrower nonReentrant {
    // ...
    uint256 collateralToReturn = loans[loanId].collateralAmount;
    address borrowerAddress = loans[loanId].borrower;  // Store borrower address
    
    lenderBalance += msg.value;
    IERC20(DAI).safeTransfer(borrowerAddress, collateralToReturn);
    
    delete loans[loanId];  // Safe to delete after transfer
    // ...
}
```