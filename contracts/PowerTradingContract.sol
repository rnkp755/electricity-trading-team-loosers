// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ElectricityTrading is Ownable {
    // Struct to represent an electricity offer
    struct Offer {
        address seller;
        uint256 pricePerKWh; // Price per kilowatt-hour
        uint256 quantityKWh; // Quantity in kilowatt-hours
        bool isRenewable;
    }

    Offer[] public offers;
    IERC20 public paymentToken; // Token used for payment

    mapping(address => uint256) public buyerBalances;
    mapping(address => uint256) public electricityPurchased;

    event OfferCreated(
        address indexed seller,
        uint256 pricePerKWh,
        uint256 quantityKWh,
        bool isRenewable
    );

    event ElectricityPurchased(
        address indexed buyer,
        address indexed seller,
        uint256 quantityKWh,
        uint256 totalCost
    );


    // Create an electricity offer
    function createOffer(
        uint256 _pricePerKWh,
        uint256 _quantityKWh,
        bool _isRenewable
    ) external {
        require(_pricePerKWh > 0, "Price must be greater than zero");
        require(_quantityKWh > 0, "Quantity must be greater than zero");
        offers.push(
            Offer({
                seller: msg.sender,
                pricePerKWh: _pricePerKWh,
                quantityKWh: _quantityKWh,
                isRenewable: _isRenewable
            })
        );
        emit OfferCreated(msg.sender, _pricePerKWh, _quantityKWh, _isRenewable);
    }

    // Purchase electricity
    function purchaseElectricity(uint256 _offerIndex, uint256 _quantityKWh)
        external
    {
        require(_offerIndex < offers.length, "Offer does not exist");
        Offer storage offer = offers[_offerIndex];
        require(offer.quantityKWh >= _quantityKWh, "Not enough quantity available");
        uint256 totalCost = offer.pricePerKWh * _quantityKWh;
        require(
            paymentToken.transferFrom(msg.sender, offer.seller, totalCost),
            "Transfer failed"
        );
        offer.quantityKWh -= _quantityKWh;
        buyerBalances[msg.sender] += totalCost;
        electricityPurchased[msg.sender] += _quantityKWh;
        emit ElectricityPurchased(msg.sender, offer.seller, _quantityKWh, totalCost);
    }

    // Withdraw available funds
    function withdrawFunds(uint256 _amount) external {
        require(buyerBalances[msg.sender] >= _amount, "Insufficient balance");
        buyerBalances[msg.sender] -= _amount;
        paymentToken.transfer(msg.sender, _amount);
    }


    // Owner can remove an offer
    function removeOffer(uint256 _offerIndex) external onlyOwner {
        require(_offerIndex < offers.length, "Offer does not exist");
        offers[_offerIndex] = offers[offers.length - 1];
        offers.pop();
    }
}

