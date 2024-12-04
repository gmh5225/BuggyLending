# BuggyLending V1

This is a simple lending protocol designed for a single lender and borrower, where ETH is lent against DAI collateral.

## What's New in V1

Initial version of the protocol implementing:
- Single lender and borrower system
- ETH lending against DAI collateral
- Basic liquidation mechanism
- Fixed loan duration and collateral ratio

## Important Note
This protocol has bug in its liquidation mechanism. Other potential issues are out of scope for this challenge.

## Core Features

### Roles
- **Owner**: Can set who the lender and borrower are
- **Lender**: Provides ETH loans and can liquidate if conditions are met
- **Borrower**: Provides DAI as collateral to borrow ETH

### Key Functions
- **createLoan**: Lender creates loan offer with ETH
- **borrowLoan**: Borrower takes loan with DAI collateral
- **repayLoan**: Borrower repays ETH to reclaim collateral
- **liquidate**: Lender claims collateral if conditions met
- **withdrawBalance**: Lender withdraws available ETH

## Important Parameters
- Loan Duration: 20 days
- Liquidation Threshold: 150% (collateral must be worth 1.5x the loan)
- Fixed Price: 1 ETH = 3500 DAI

## How to Use

1. Owner sets the lender and borrower addresses
2. Lender creates a loan by depositing ETH
3. Borrower provides DAI collateral to take the loan
4. Borrower must repay within 20 days
5. If borrower defaults lender can liquidate
  