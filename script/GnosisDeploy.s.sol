// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PiggybankNFT.sol";
import "../src/Piggybank6551Implementation.sol";
import "reference/src/interfaces/IERC6551Registry.sol";

contract DeployScript is Script {
    IERC6551Registry gnosisRegistry =
        IERC6551Registry(0x02101dfB77FDE026414827Fdc604ddAF224F0921);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("GNOSIS_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Piggybank6551Implementation piggybank6551Implementation = new Piggybank6551Implementation();
        PiggybankNFT piggybankNFT = new PiggybankNFT(
            address(piggybank6551Implementation),
            address(gnosisRegistry),
            1000,
            10000000000000000
        );

        vm.stopBroadcast();
    }
}
