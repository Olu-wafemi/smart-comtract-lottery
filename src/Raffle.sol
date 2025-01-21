// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title Raffle Contract
 * @author Oluwafemi
 * @notice For creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {
    //i_ stands for immutable, signifying that the varaible cnnot be changed
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public {}

    function pickWinner() public {}

    /**Getter Functions */

    function getEntrancefee() external view returns (uint256) {
        return i_entranceFee;
    }
}
