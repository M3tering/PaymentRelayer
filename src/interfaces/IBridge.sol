// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

error TransferError();

interface IBridge {
    function bridge(uint256 amount, address sender, address receiver) external payable;
}
