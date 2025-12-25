// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title SaleDeal - escrow for car sale
/// @notice Seller (Mastalerz) lists the car for sale, Buyer (Kowalski) pays the contract price,
/// Buyer confirms the sale -> funds are transferred to the Seller's pendingWithdrawals (pull pattern),
/// Ownership of the car (represented as address mastalerz) is transferred to the Buyer.

contract SaleDeal {
    address public mastalerz; // current car owner (Seller on deploy)
    address public kowalski;  // current Buyer (if purchase initiated)
    uint256 public price;      // price listed for sale (0 = not for sale)

    mapping(address => uint256) public pendingWithdrawals; // funds to be withdrawn (pull) 
    mapping(address => uint256) private _deposits;        // Buyers' deposits 

    event Listed(address indexed owner, uint256 price); 
    event Unlisted(address indexed owner); 
    event Bought(address indexed buyer, uint256 amount); 
    event SaleConfirmed(address indexed oldOwner, address indexed newOwner, uint256 amount); 
    event PurchaseCancelled(address indexed buyer, uint256 amount); 
    event Withdrawal(address indexed to, uint256 amount); 

    modifier onlyMastalerz() { 
        require(msg.sender == mastalerz, "only mastalerz"); 
        _; 
    } 

    constructor() { 
        mastalerz = msg.sender; 
    }

    /// @notice Lists a car for sale, specifying the price (in WEI).
    function listForSale(uint256 _price) external onlyMastalerz {
        require(_price > 0, "price>0");
        require(price == 0, "already listed");
        price = _price;
        emit Listed(mastalerz, _price);
    }

    /// @notice Deletes the ad (Mastalerz only), only if there is no pending buyer.
    function delist() external onlyMastalerz {
        require(price != 0, "not listed");
        require(kowalski == address(0), "has pending buyer");
        price = 0;
        emit Unlisted(mastalerz);
    }

    /// @notice The buyer initiates the purchase by sending the exact `price` amount
    function buy() external payable {
        require(price != 0, "not for sale");
        require(kowalski == address(0), "already pending buyer");
        require(msg.value == price, "incorrect value");

        kowalski = msg.sender;
        _deposits[msg.sender] = msg.value;

        emit Bought(msg.sender, msg.value);
    }

    /// @notice The buyer can cancel the purchase (refund) until the seller confirms
    function cancelPurchase() external {
        require(kowalski == msg.sender, "not pending buyer");
        uint256 amount = _deposits[msg.sender];
        require(amount > 0, "no deposit"); 

        // clear state 
        _deposits[msg.sender] = 0; 
        kowalski = address(0); 

        // pull pattern
        pendingWithdrawals[msg.sender] += amount; 

        emit PurchaseCancelled(msg.sender, amount); 
    } 

    /// @notice The seller confirms the sale
    function confirmSale() external onlyMastalerz { 
        require(kowalski != address(0), "no pending buyer"); 
        uint256 amount = _deposits[kowalski]; 
        require(amount == price, "deposit mismatch"); 

        // EFFECTS 
        _deposits[kowalski] = 0; 
        pendingWithdrawals[mastalerz] += amount; 

        address oldOwner = mastalerz; 
        address newOwner = kowalski;

        // Transfer of ownership
        mastalerz = newOwner;

        // Sale completed
        kowalski = address(0);
        price = 0;

        emit SaleConfirmed(oldOwner, newOwner, amount);
    }

    /// @notice Withdrawing collected funds (pull pattern)
    function withdrawPayments() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "no funds");

        pendingWithdrawals[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "withdraw failed");

        emit Withdrawal(msg.sender, amount);
    } 

    /// @notice View: deposit of a given address (buyer) 
    function depositOf(address who) external view returns (uint256) { 
        return _deposits[who]; 
    } 

    receive() external payable { 
        revert("use buy()"); 
    }
}
