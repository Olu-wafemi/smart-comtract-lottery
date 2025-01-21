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
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    /**Events */

    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreEthToEnterRaffle();
        }

        s_players.push(payable(msg.sender));
        //Emit event each time storage is updated
        emit RaffleEntered(msg.sender);
    }

    //1. Get a random number
    //2. Use random number to pick a player
    //3. Be autimatically called
    function pickWinner() external {
        // check to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {}
    }

    /**Getter Functions */

    function getEntrancefee() external view returns (uint256) {
        return i_entranceFee;
    }
}
