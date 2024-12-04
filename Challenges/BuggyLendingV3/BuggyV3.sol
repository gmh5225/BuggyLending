// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BuggyLendingV3 is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public immutable DAI;
    address public lender;
    address public borrower;

    // Fixed price: 1 ETH = 3500 DAI (for simplicity)
    uint256 public constant DAI_PRICE = 1e18/3500; // ETH per DAI

    modifier onlyLender() {
        require(msg.sender == lender, "Only lender can call");
        _;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "Only borrower can call");
        _;
    }

    struct Loan {
        uint256 loanAmount;      // Amount in ETH
        uint256 collateralAmount;
        uint256 startTime;
        uint256 dueDate;
        bool isActive;
        bool isBorrowed;
        address borrower;
    }

    // Constants
    uint256 public constant LOAN_DURATION = 20 days;
    uint256 public constant LIQUIDATION_THRESHOLD = 150; // 150% collateralization ratio
    
    // Replace single loan with mapping
    mapping(uint256 => Loan) public loans;
    uint256 public nextLoanId;
    
    // Track lender's ETH balance
    uint256 public lenderBalance;
    
    event LoanCreated(uint256 indexed loanId, uint256 amount);
    event LoanBorrowed(uint256 indexed loanId, uint256 collateralAmount);
    event LoanRepaid(uint256 indexed loanId, uint256 amount);
    event LoanLiquidated(uint256 indexed loanId);
    event BorrowerUpdated(address newBorrower);
    event LenderUpdated(address newLender);

    constructor(address _dai) {
        require(_dai != address(0), "Invalid DAI address");
        DAI = _dai;
    }

    function setBorrower(address _borrower) external onlyOwner {
        require(_borrower != address(0), "Invalid borrower address");
        borrower = _borrower;
        emit BorrowerUpdated(_borrower);
    }

    function setLender(address _lender) external onlyOwner {
        require(_lender != address(0), "Invalid lender address");
        lender = _lender;
        emit LenderUpdated(_lender);
    }

    function createLoan() external payable onlyLender nonReentrant {
        require(msg.value > 0, "Invalid loan amount");
        
        uint256 loanId = nextLoanId++;
        
        loans[loanId] = Loan({
            loanAmount: msg.value,
            collateralAmount: 0,
            startTime: 0,
            dueDate: 0,
            isActive: true,
            isBorrowed: false,
            borrower: address(0)
        });

        lenderBalance += msg.value;
        
        emit LoanCreated(loanId, msg.value);
    }

    function borrowLoan(uint256 loanId, uint256 collateralAmount) external onlyBorrower nonReentrant {
        require(loans[loanId].isActive && !loans[loanId].isBorrowed, "Loan not available");
        require(collateralAmount > 0, "Invalid collateral amount");

        uint256 collateralValue = collateralAmount * DAI_PRICE;
        uint256 requiredCollateral = loans[loanId].loanAmount * LIQUIDATION_THRESHOLD / 100;
        collateralValue = collateralValue/1e18;
        
        require(collateralValue >= requiredCollateral, "Insufficient collateral");

        IERC20(DAI).safeTransferFrom(msg.sender, address(this), collateralAmount);

        loans[loanId].collateralAmount = collateralAmount;
        loans[loanId].startTime = block.timestamp;
        loans[loanId].dueDate = block.timestamp + LOAN_DURATION;
        loans[loanId].isBorrowed = true;
        loans[loanId].borrower = msg.sender;

        (bool success, ) = payable(borrower).call{value: loans[loanId].loanAmount}("");
        require(success, "ETH transfer failed");
        
        emit LoanBorrowed(loanId, collateralAmount);
    }

    function commitCollateral(uint256 loanId, uint256 amount) external onlyBorrower nonReentrant {
        require(loans[loanId].isActive, "Loan not active");

        uint256 collateralValue = amount * DAI_PRICE;
        uint256 requiredCollateral = loans[loanId].loanAmount * LIQUIDATION_THRESHOLD / 100;
        collateralValue = collateralValue/1e18;
        
        require(collateralValue > requiredCollateral, "Insufficient collateral");

        IERC20(DAI).safeTransferFrom(msg.sender, address(this), amount);
        
        if (loans[loanId].collateralAmount > 0) {
            IERC20(DAI).safeTransfer(borrower, loans[loanId].collateralAmount);
        }

        loans[loanId].collateralAmount = amount;

        if (!loans[loanId].isBorrowed) {
            loans[loanId].startTime = block.timestamp;
            loans[loanId].dueDate = block.timestamp + LOAN_DURATION;
            loans[loanId].isBorrowed = true;
            
            (bool success, ) = payable(borrower).call{value: loans[loanId].loanAmount}("");
            require(success, "ETH transfer failed");
        }
        
        emit LoanBorrowed(loanId, amount);
    }

    function canLiquidate(uint256 loanId) public view returns (bool) {
        if (!loans[loanId].isActive || !loans[loanId].isBorrowed) return false;
        
        bool isDefaulted = block.timestamp > loans[loanId].startTime + LOAN_DURATION;
        
        uint256 collateralValue = loans[loanId].collateralAmount * DAI_PRICE;
        uint256 requiredCollateral = loans[loanId].loanAmount * LIQUIDATION_THRESHOLD / 100;
        collateralValue = collateralValue/1e18;

        return isDefaulted || collateralValue < requiredCollateral;
    }

    function liquidate(uint256 loanId) external onlyLender nonReentrant {
        require(canLiquidate(loanId), "Cannot liquidate this loan");
        require(loans[loanId].isActive && loans[loanId].isBorrowed, "Loan not active or not borrowed");
        require(loans[loanId].collateralAmount > 0, "collateralAmount > 0");
        
        loans[loanId].isActive = false;
        lenderBalance -= loans[loanId].loanAmount;
        
        IERC20(DAI).safeTransfer(lender, loans[loanId].collateralAmount);
        
        emit LoanLiquidated(loanId);
    }

    function repayLoan(uint256 loanId) external payable onlyBorrower nonReentrant {
        require(loans[loanId].isActive && loans[loanId].isBorrowed, "Loan not active or not borrowed");
        require(msg.value >= loans[loanId].loanAmount, "Insufficient repayment amount");

        uint256 collateralToReturn = loans[loanId].collateralAmount;
        
        delete loans[loanId];
        lenderBalance += msg.value;

        IERC20(DAI).safeTransfer(loans[loanId].borrower, collateralToReturn);

        emit LoanRepaid(loanId, msg.value);
    }

    function withdrawBalance() external onlyLender nonReentrant {
        uint256 amount = lenderBalance;
        require(amount > 0, "No balance to withdraw");
        
        // Deactivate the loan if it hasn't been borrowed yet
        for (uint256 loanId = 0; loanId < nextLoanId; loanId++) {
            if (loans[loanId].isActive && !loans[loanId].isBorrowed) {
                loans[loanId].isActive = false;
            }
        }
        
        lenderBalance = 0;
        
        (bool success, ) = payable(lender).call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {}
}