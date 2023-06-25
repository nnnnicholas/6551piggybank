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
    PiggybankNFT piggybankNFT;

    function setUp() public {
        vm.deal(deployer, 1000 ether);
        vm.deal(minter, 1000 ether);
        vm.startPrank(deployer, deployer);
        goerliRegistry = IERC6551Registry(
            0x02101dfB77FDE026414827Fdc604ddAF224F0921
        );
        piggybank6551Implementation = new Piggybank6551Implementation();
        piggybankNFT = new PiggybankNFT(
            address(piggybank6551Implementation),
            address(goerliRegistry),
            100,
            10000000000000000
        );
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

    function testGetAccount() public {
        testMint();
        address accountAccordingToNFT = piggybankNFT.getAccount(1);
        address accountAccordingToRegistry = goerliRegistry.account(
            address(piggybank6551Implementation),
            31337, // HEVM chainId for some reason
            address(piggybankNFT),
            1,
            0
        );
        assertEq(accountAccordingToNFT, accountAccordingToRegistry);
    }

    function testAddEth() public {
        testMint();
        vm.startPrank(minter, minter);
        piggybankNFT.getAccount(1).call{value: 1.2345 ether}("");
        vm.stopPrank();
    }
    function testAddMoreEth() public {
        testAddEth();
        vm.startPrank(minter, minter);
        piggybankNFT.getAccount(1).call{value: 100.1 ether}("");
        vm.stopPrank();
    }
    function testAddEvenMoreEth() public {
        testAddMoreEth();
        vm.startPrank(minter, minter);
        piggybankNFT.getAccount(1).call{value: 100.14494949 ether}("");
        vm.stopPrank();
    }

    function testUri() public {
        testMint();
        testAddEvenMoreEth();
        string memory uri = piggybankNFT.tokenURI(1);
        string memory x = piggybankNFT.tokenURI(1);
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./open.js";
        inputs[2] = x;
        // bytes memory res = vm.ffi(inputs);
        vm.ffi(inputs);
    }
}
