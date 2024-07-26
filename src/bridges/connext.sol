// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "../interfaces/IBridge.sol";
import {IConnext} from "../interfaces/IConnext.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleConnextBridge is IBridge {
    IERC20 public immutable ERC20_DAI;
    IConnext public immutable CONNEXT;

    uint256 public constant SLIPPAGE_BPS = 70;
    uint32 public constant GNOSIS_DOMAIN_ID = 6778479;
    address public constant WXDAI_UNWRAPPER = 0x642c27a96dFFB6f21443A89b789a3194Ff8399fa;

    constructor(address connext, address dai) {
        CONNEXT = IConnext(connext);
        ERC20_DAI = IERC20(dai);
    }

    function bridge(uint256 amount, address sender, address receiver) external payable {
        if (!ERC20_DAI.transferFrom(sender, address(this), amount)) revert TransferError();
        ERC20_DAI.approve(address(CONNEXT), amount);
        bytes memory callData = abi.encode(receiver);

        CONNEXT.xcall{value: msg.value}(// msg.value is the fee offered to relayers
            GNOSIS_DOMAIN_ID,           // _destination: Domain ID of the destination chain
            WXDAI_UNWRAPPER,            // _to: Unwrapper contract
            address(ERC20_DAI),         // _asset: address of the token contract
            receiver,                   // _delegate: address that can revert or forceLocal on destination
            amount,                     // _amount: amount of tokens to transfer
            SLIPPAGE_BPS,               // _slippage: the maximum amount of slippage the user will accept in BPS (e.g. 30 = 0.3%)
            callData                    // _callData: calldata with encoded recipient address
        );
    }
}
