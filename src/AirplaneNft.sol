// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AceToken} from "./AceToken.sol";

contract AirplaneNft is ERC721 {
    error AirplaneNft__SendMoreEth();
    error AirplaneNft__NotOwner();
    error AirplaneNft__ExcessReturnFailed();
    error AirplaneNft__WithdrawalFailed();
    error AirplaneNft__InsufficientBalance();
    error AirplaneNft__NotEnoughTokens();
    error AirplaneNft__PaymentFailed();

    using PriceConverter for uint256;

    uint256 private s_tokenCounter;
    string private s_airplaneUri;
    mapping(uint256 => string) private s_tokenIdToUri;
    uint256 private constant MINIMUM_USD = 5e18;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;
    uint256 private s_price;
    AceToken private s_paymentToken;

    constructor(
        address _priceFeed,
        AceToken _paymentToken,
        uint256 _price
    ) ERC721("Airplane NFT", "AP") {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        i_owner = msg.sender;
        s_tokenCounter = 0;
        s_airplaneUri = "https://ipfs.io/ipfs/QmaA83SY1dd7BsnNwRx8GocGFu9pbcRbzmNnyNN5oT4quW?filename=airplane.json";
        s_paymentToken = _paymentToken;
        s_price = _price;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert AirplaneNft__NotOwner();
        }
        _;
    }

    function mintNFTWithEth() public payable {
        uint256 ethInUsd = msg.value.getConversionRate(s_priceFeed);

        if (ethInUsd < MINIMUM_USD) {
            revert AirplaneNft__SendMoreEth();
        }

        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToUri[s_tokenCounter] = s_airplaneUri;
        s_tokenCounter++;
    }

    function mintNFTWithAce() public {
        uint256 spenderBalance = s_paymentToken.balanceOf(msg.sender);

        if (spenderBalance < s_price) {
            revert AirplaneNft__NotEnoughTokens();
        }

        bool success = s_paymentToken.transferFrom(
            msg.sender,
            i_owner,
            s_price
        );

        if (!success) {
            revert AirplaneNft__PaymentFailed();
        }

        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToUri[s_tokenCounter] = s_airplaneUri;
        s_tokenCounter++;
    }

    function withdraw() public onlyOwner {
        if (address(this).balance == 0) {
            revert AirplaneNft__InsufficientBalance();
        }
        (bool success, ) = payable(i_owner).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert AirplaneNft__WithdrawalFailed();
        }
    }

    function tokenURI(
        uint256 _id
    ) public view override returns (string memory) {
        return s_tokenIdToUri[_id];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}
