// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IBridge.sol";
import "./interfaces/IERC6551Registry.sol";
import {Pausable} from "@openzeppelin/contracts@5.0.2/utils/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts@5.0.2/access/AccessControl.sol";

/// @custom:security-contact info@whynotswitch.com
contract PaymentRelayer is Pausable, AccessControl {
    address public constant TBA_IMPLEMENTATION = 0x8ad12E4ac066f7Cb38B0e0a6F3c60e37e0CF7508;
    address public constant TBA_REGISTRY = 0x000000006551c19487814612e58FE06813775758;
    address public constant M3TER = 0x39fb420Bd583cCC8Afd1A1eAce2907fe300ABD02;
    uint256 public constant GNOSIS_CHAIN_ID = 100;

    bytes32 public constant CURATOR = keccak256("CURATOR");
    bytes32 public constant PAUSER = keccak256("PAUSER");

    mapping(address => bool) public bridges;
    address public DEFAULT_BRIDGE;

    error BadBridge();
    error InputIsZero();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CURATOR, msg.sender);
        _grantRole(PAUSER, msg.sender);
    }

    function _curateBridge(address bridgeAddress, bool state, bool defaultBridge) external onlyRole(CURATOR) {
        if (defaultBridge) DEFAULT_BRIDGE = bridgeAddress;
        bridges[bridgeAddress] = state;
    }

    function pay(uint256 amount, uint256 tokenId) external payable whenNotPaused {
        pay(amount, tokenId, DEFAULT_BRIDGE);
    }

    function pay(uint256 amount, uint256 tokenId, address bridgeAddress) public payable whenNotPaused {
        if (amount == 0) revert InputIsZero();
        if (bridges[bridgeAddress] == false) revert BadBridge();
        IBridge(bridgeAddress).bridge{value: msg.value}(amount, msg.sender, m3terAccount(tokenId));
    }

    function pause() public onlyRole(PAUSER) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER) {
        _unpause();
    }

    function m3terAccount(uint256 tokenId) public view returns (address) {
        return IERC6551Registry(TBA_REGISTRY).account(TBA_IMPLEMENTATION, 0x0, GNOSIS_CHAIN_ID, M3TER, tokenId);
    }}
