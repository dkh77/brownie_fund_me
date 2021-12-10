// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // import eth/usd price feed contract

//contract MockV3Aggregator is AggregatorV3Interface, AggregatorInterface

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 25 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "Minimum requiremens are not met."
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version(); // gets version of the AggregatorV3Interface
    }

    // what the ETH => USD converstion rate is
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / 1000000000000000000;
        return ethAmountInUSD;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimum USD
        uint256 minimumUSD = 25 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (precision * minimumUSD) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //only want the ownder to do this
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funders = funders[fundersIndex];
            addressToAmountFunded[funders] = 0;
        }
        funders = new address[](0);
    }
}
