// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IIfaPriceFeed} from "./Interface/IIfaPriceFeed.sol";
import {Ownable} from "solady-0.1.12/src/auth/Ownable.sol";
import {ReceiverTemplate} from "./ReceiverTemplate.sol";

contract IfaPriceFeedVerifier is ReceiverTemplate {
    struct SumissionData {
        bytes32 assesetindex;
        IIfaPriceFeed.PriceFeed price;
    }
    SumissionData  sumissionData;
    error InvalidRelayerNode(address _address);
    error OnlyRelayerNode(address _caller);
    error InvalidAssetIndexorPriceLength();
    error InvalidAssePrice();

    event RelayerNodeSet(address indexed newRelayerNode, address indexed oldRelayerNode);

    address public relayerNode;
    IIfaPriceFeed public immutable IfaPriceFeed;


    constructor(address _relayerNode, address _IIfaPriceFeed, address _owner, address _forwarderAddress)
        ReceiverTemplate(_forwarderAddress, _owner)
    {
        // _initializeOwner(_owner); // setting owner of contract
        relayerNode = _relayerNode;
        IfaPriceFeed = IIfaPriceFeed(_IIfaPriceFeed);
    }

    modifier onlyRelayerNode() {
        require(msg.sender == relayerNode, OnlyRelayerNode(msg.sender));
        _;
    }

    function submitPriceFeed(bytes32[] calldata _assetindex, IIfaPriceFeed.PriceFeed[] calldata _prices)
        external
        onlyRelayerNode
    {
        _submitPriceFeed(_assetindex, _prices);
    }

    function _submitPriceFeed(bytes32[] memory _assetindex, IIfaPriceFeed.PriceFeed[] memory _prices) internal {
        require(_assetindex.length == _prices.length, InvalidAssetIndexorPriceLength());

        for (uint256 i = 0; i < _assetindex.length; i++) {
            bytes32 pair = _assetindex[i];
            IIfaPriceFeed.PriceFeed memory currentPriceFeed = _prices[i];
            require(currentPriceFeed.price > 0, InvalidAssePrice());
            uint256 currenttimestamp = currentPriceFeed.lastUpdateTime;
            (IIfaPriceFeed.PriceFeed memory prevPriceFeed,) = IfaPriceFeed.getAssetInfo(pair);
            if (prevPriceFeed.lastUpdateTime >= currenttimestamp) {
                continue;
            }

            IfaPriceFeed.setAssetInfo(pair, currentPriceFeed);
        }
    }

    function setRelayerNode(address _relayerNode) external onlyOwner {
        require(_relayerNode != address(0), InvalidRelayerNode(_relayerNode));
        address oldRelayerNode = relayerNode;
        relayerNode = _relayerNode;
        emit RelayerNodeSet(_relayerNode, oldRelayerNode);
    }
    //@audit make it private 
    function proceesTheSumission(SumissionData memory data) public {
        bytes32[] memory assesetindies = new bytes32[](1);
        IIfaPriceFeed.PriceFeed[] memory prices = new  IIfaPriceFeed.PriceFeed[](1);
        assesetindies[0]  = data.assesetindex;
        prices[0] =  data.price;
        _submitPriceFeed(assesetindies,prices);
    }

    function _processReport(bytes calldata report) internal override {
        (SumissionData memory data) = abi.decode(report, (SumissionData));
        proceesTheSumission(data);
    }

    ///@dev Override to return true to prevent double-initialization.

    function _guardInitializeOwner() internal pure override returns (bool guard) {
        guard = true;
    }
}
