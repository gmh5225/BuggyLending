# BuggyLending V2

This is the second version of the lending protocol that fixes the liquidation timing bug from V1 and introduces a new collateral management feature.

## What's New in V2
- Fixed liquidation timing bug from V1
- Added dynamic collateral management
- Introduced `commitCollateral()` function for active position management

## Important Note
While the V1 liquidation timing bug is fixed, the new collateral management feature introduces its own issue. Other potential issues are out of scope for this challenge.

## Core Features

### Roles
- **Owner**: Can set who the lender and borrower are
- **Lender**: Provides ETH loans and can liquidate if conditions are met
- **Borrower**: Provides DAI as collateral to borrow ETH

### Key Functions
- All V1 functions remain
- **commitCollateral**: New function for updating collateral amount
  - Update collateral after loan creation
  - Swap old collateral for new collateral
  - Manage collateral ratio actively

## Important Parameters
- Loan Duration: 20 days
- Liquidation Threshold: 150% (collateral must be worth 1.5x the loan)
- Fixed Price: 1 ETH = 3500 DAI

## How to Use

1. Owner sets the lender and borrower addresses
2. Lender creates a loan by depositing ETH
3. Borrower provides initial DAI collateral to take the loan
4. Borrower can update collateral using `commitCollateral()`
5. Loan must be repaid within 20 days
6. Lender can liquidate if conditions are met