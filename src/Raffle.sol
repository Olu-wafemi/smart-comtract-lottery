// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle Contract
 * @author Oluwafemi
 * @notice For creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */
abstract contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error Raffle__SendMoreEthToEnterRaffle();
    //i_ stands for immutable, signifying that the varaible cnnot be changed

    uint16 private constant REQUEST_CONFIRMATIONS = 3; //The numbeer of confoirmations the contract has to have before retrieving random number from the block
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private i_keyhash;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);

    //When you inherit a contract that has  a constructor with arguments, you have to add the contract's constructor to the child's contract constructor

    //address vrfCoordinator is the VRFConsumerBaseV2Plus constructor argument, which is the address of the Vrfcoordinator contract, gotten directly from the chainlink docs

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane, //Keyhash for maximum gas that will be used for getting random number using chainlink,
        uint256 subscriptionId, //Id for funding in chainlink
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyhash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
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
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        //Get arandom number from cahinlink after the time has passed
        //Chainlink vrf is used to achieve this

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyhash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    /**
     * Getter Functions
     */
    function getEntrancefee() external view returns (uint256) {
        return i_entranceFee;
    }
}
