// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title Raffle Contract
 * @author Oluwafemi
 * @notice For creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {
    /**Errors */
    error Raffle__SendMoreEthToEnterRaffle();
    //i_ stands for immutable, signifying that the varaible cnnot be changed
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    /**Events */

    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreEthToEnterRaffle();
        }

        s_players.push(payable(msg.sender));
        //Emit event each time storage is updated
        emit RaffleEntered(msg.sender);
    }

    function pickWinner() public {}

    /**Getter Functions */

    function getEntrancefee() external view returns (uint256) {
        return i_entranceFee;
    }
}
