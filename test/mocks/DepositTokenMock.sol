// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Mock contract for deposit token.
 * @dev Mock contract that will be used during the local testing.
 */
contract DepositTokenMock is ERC20 {
    constructor() ERC20("Token", "DT") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}