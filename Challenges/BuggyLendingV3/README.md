# BuggyLending V3

This is the third version of the lending protocol that fixes the collateral management issues from V2 and introduces support for multiple concurrent loans.

## What's New in V3
- Fixed collateral management issues from V2
- Added support for multiple concurrent loans
- Introduced unique loan IDs and tracking system
- Independent management of multiple positions

## Important Note
This version fixes V2's collateral management bugs but contains an issue in the repayment system. Other potential issues are out of scope for this challenge.

## Core Features

### Roles
- **Owner**: Can set who the lender and borrower are
- **Lender**: Provides ETH loans and can liquidate if conditions are met
- **Borrower**: Provides DAI as collateral to borrow ETH

### Key Functions
- All V2 functions remain
- Enhanced loan tracking system
- Multiple loan creation and management
- Independent collateral ratio tracking per loan

## Important Parameters
- Loan Duration: 20 days
- Liquidation Threshold: 150% (collateral must be worth 1.5x the loan)
- Fixed Price: 1 ETH = 3500 DAI

## How to Use

1. Owner sets the lender and borrower addresses
2. Lender creates loans by depositing ETH (each with unique ID)
3. Borrower provides DAI collateral to take any available loan
4. Loans must be repaid within 20 days
5. Lender can liquidate if conditions are met
6. Each loan is managed independently
