//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    //function run() public {}

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperconfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createsubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createsubscription
                .createSubscription(config.vrfCoordinator);
            //Fund it
            FundSubscription fundsubscription = new FundSubscription();
            fundsubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.link
            );
            //AddConsuymer
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addconsumer = new AddConsumer();
        addconsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId
        );
        return (raffle, helperconfig);
    }
}
