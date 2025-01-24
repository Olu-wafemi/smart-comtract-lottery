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
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error Raffle__SendMoreEthToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 rafflestate
    );
    //i_ stands for immutable, signifying that the varaible cnnot be changed
    /**Type declarations */

    //This Enum is used to track the state of operations

    enum RaffleState {
        OPEN, //Integer 0
        CALCULATING //Integer 1
    }

    /**State Variables */
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
    address private s_recentWinner;

    RaffleState private s_rafflestate;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

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

        s_lastTimeStamp = block.timestamp;
        s_rafflestate = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreEthToEnterRaffle();
        }

        if (s_rafflestate != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        //Emit event each time storage is updated
        emit RaffleEntered(msg.sender);
    }

    //When should the winner be picked
    /**
     * @dev This is the function that the chainlink node wil call to see if the lottery is ready to have a winner picked.
     * The following should be true in order fo upkeepNeeded to be true
     * 1. The time interval has passed between raffle runs
     * 2.  The lottery is open
     * 3. The contract has Eth
     * 4. Implicitly, your subscription has LINK
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ignored
     */

    function checkUpKeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPssed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_rafflestate == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPssed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    //1. Get a random number
    //2. Use random number to pick a player
    //3. Be automatically called using Chainlink Automation
    function performUpkeep(bytes calldata /* performData */) external {
        // check to see if enough time has passed
        (bool upkeedNeeded, ) = checkUpKeep("");
        if (!upkeedNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_rafflestate)
            );
        }

        s_rafflestate = RaffleState.CALCULATING;
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

        s_vrfCoordinator.requestRandomWords(request);
    }

    //CEI: Chcecks Effects, Interactons
    //This fulfillrandom words is the callback function that returns the random words, it has to be in this contract compulsoriyly since we've inherited the VRf contract which is an abstract contract
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        //Checks. More Gas efficient
        //Effect (Internal Contract State)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_rafflestate = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        // Interactions (External conrtract interctions)
        //Give the winner the balacne of the contract
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEntrancefee() external view returns (uint256) {
        return i_entranceFee;
    }

    /**Getter functions */
    function getRaffleState() external view returns (RaffleState) {
        return s_rafflestate;
    }
}
