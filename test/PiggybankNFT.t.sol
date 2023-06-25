// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/PiggybankNFT.sol";
import "../src/Piggybank6551Implementation.sol";
import "reference/src/interfaces/IERC6551Registry.sol";

contract Piggybank6551ImplementationTest is Test {
    address deployer = address(420);
    address minter = address(69);
    //  Setup vars
    uint256 constant FORK_BLOCK_NUMBER = 9236519; // All tests executed at this block
    string GOERLI_RPC_URL = "GOERLI_RPC_URL";
    uint256 forkId =
        vm.createSelectFork(vm.envString(GOERLI_RPC_URL), FORK_BLOCK_NUMBER);

    IERC6551Registry goerliRegistry;

    Piggybank6551Implementation piggybank6551Implementation;
    PiggybankNFT piggybankNFT =
        new PiggybankNFT(
            address(piggybank6551Implementation),
            address(goerliRegistry),
            100,
            10000000000000000
        );

    function setUp() public {
        vm.deal(deployer, 10 ether);
        vm.deal(minter, 10 ether);
        vm.startPrank(deployer, deployer);
        goerliRegistry = IERC6551Registry(
            0x02101dfB77FDE026414827Fdc604ddAF224F0921
        );
        piggybank6551Implementation = new Piggybank6551Implementation();
        vm.stopPrank();
    }

    function testMint() public {
        vm.startPrank(minter, minter);
        piggybankNFT.mint{value: 10000000000000000}();
        vm.stopPrank();
        // check that nft 1 exists
    }

    function testCreateAccount() public {
        address nftAccount = goerliRegistry.account(
            address(piggybank6551Implementation),
            5,
            address(piggybankNFT),
            1,
            0
        );
    }
}
