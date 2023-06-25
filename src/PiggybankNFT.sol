// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Base64} from "base64-sol/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
// import "./MyERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "reference/src/lib/ERC6551AccountLib.sol";
import "reference/src/interfaces/IERC6551Registry.sol";
import "juice-token-resolver/src/Libraries/StringSlicer.sol";

/// @title PiggybankNFT
/// @notice An NFT piggybank that accepts ETH.
/// @dev An ERC-721 NFT piggybank implementation.
/// @author nnnnicholas
contract PiggybankNFT is ERC721 {
    using Strings for uint256; // Turns uints into strings
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public totalSupply; // The total number of tokens minted on this contract
    address public immutable implementation; // The Piggybank6551Implementation address
    IERC6551Registry public immutable registry; // The 6551 registry address
    uint public immutable chainId = block.chainid; // The chainId of the network this contract is deployed on
    address public immutable tokenContract = address(this); // The address of this contract
    uint salt = 0; // The salt used to generate the account address
    uint public immutable maxSupply; // The maximum number of tokens that can be minted on this contract
    uint public immutable price;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _implementation,
        address _registry,
        uint _maxSupply,
        uint _price
    ) ERC721("PiggybankNFT", "PIGGY") {
        implementation = _implementation;
        registry = IERC6551Registry(_registry);
        maxSupply = _maxSupply;
        price = _price;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAccount(uint tokenId) public view returns (address) {
        return
            registry.account(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt
            );
    }

    function createAccount(uint tokenId) public returns (address) {
        return
            registry.createAccount(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt,
                ""
            );
    }

    function addEth(uint tokenId) external payable {
        address account = getAccount(tokenId);
        (bool success, ) = account.call{value: msg.value}("");
        require(success, "Failed to send ETH");
    }

    function mint() external payable {
        require(totalSupply < maxSupply, "Max supply reached");
        require(msg.value >= price, "Insufficient funds");
        _safeMint(msg.sender, ++totalSupply);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        address account = getAccount(tokenId);
        string[] memory uriParts = new string[](4);
        string memory balance = "0";
        string memory ethBalanceTwoDecimals = "0";
        if (address(account).balance > 0) {
            balance = (address(account).balance / 10 ** 16).toString();
            ethBalanceTwoDecimals = string.concat(
                StringSlicer.slice(balance, 0, bytes(balance).length - 2),
                ".",
                StringSlicer.slice(
                    balance,
                    bytes(balance).length - 2,
                    bytes(balance).length
                )
            );
        }
        if (ownerOf(tokenId) == account) {
            uriParts[0] = string("data:application/json;base64,");
            uriParts[1] = string(
                abi.encodePacked(
                    '{"name":"Piggybank #',
                    tokenId.toString(),
                    ' (Burned)",',
                    '"description":"Piggybanks are NFT owned accounts (6551) that accept ETH and only return it when burned. Burned NFTs are sent to their own 6551 addresses, making them ",',
                    '"attributes":[{"trait_type":"Balance","value":"0"},{"trait_type":"Status","value":"Burned"}],',
                    '"image":"data:image/svg+xml;base64,'
                )
            );
            uriParts[2] = Base64.encode(
                abi.encodePacked(
                    '<svg width="1000" height="1000" viewBox="0 0 1000 1000" xmlns="http://www.w3.org/2000/svg">',
                    '<rect width="1000" height="1000" fill="black"/>',
                    '<text x="80" y="276" fill="white" font-family="Helvetica" font-size="130" font-weight="bold">',
                    "Piggybank #",
                    tokenId.toString(),
                    '</text>',
                    '<text x="80" y="425" fill="white" font-family="Helvetica" font-size="130" font-weight="bold">',
                    " is burned </text>",
                    "</svg>"
                )
            );
            uriParts[3] = string('"}');
        } else {
            uriParts[0] = string("data:application/json;base64,");
            uriParts[1] = string(
                abi.encodePacked(
                    '{"name":"Piggybank #',
                    tokenId.toString(),
                    '",',
                    '"description":"Piggybanks are NFT owned accounts (6551) that accept ETH and only return it when burned. Burned NFTs are sent to their own 6551 addresses, making them ",',
                    '"attributes":[{"trait_type":"Balance","value":"',
                    ethBalanceTwoDecimals,
                    ' ETH"},{"trait_type":"Status","value":"Exists"}],',
                    '"image":"data:image/svg+xml;base64,'
                )
            );
            uriParts[2] = Base64.encode(
                abi.encodePacked(
                    '<svg width="1000" height="1000" viewBox="0 0 1000 1000" xmlns="http://www.w3.org/2000/svg">',
                    '<rect width="1000" height="1000" fill="hsl(',
                    (address(account).balance / 10 ** 17).toString(),
                    ', 78%, 56%)"/>',
                    '<text x="80" y="276" fill="white" font-family="Helvetica" font-size="130" font-weight="bold">',
                    "Piggybank #",
                    tokenId.toString(),
                    '</text>',
                    '<text x="80" y="425" fill="white" font-family="Helvetica" font-size="130" font-weight="bold">',
                    " contains </text>",
                    '<text x="80" y="574" fill="white" font-family="Helvetica" font-size="130" font-weight="bold">',
                    ethBalanceTwoDecimals,
                    " ETH",
                    "</text>",
                    "</svg>"
                )
            );
            uriParts[3] = string('"}');
        }

        string memory uri = string.concat(
            uriParts[0],
            Base64.encode(
                abi.encodePacked(uriParts[1], uriParts[2], uriParts[3])
            )
        );

        return uri;
    }

    function burn(uint256 tokenId) external virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ownerOf(tokenId);

        // Clear approvals
        // Should implement a function that zeroes out token approvals in the 721 contract -- because we can't access the _tokenApprovals array from this contract.
        //    function removeTokenApprovals(uint tokenId) public virtual {
        //   require(
        //     _isApprovedOrOwner(_msgSender(), tokenId),
        //   "ERC721: transfer caller is not owner nor approved"
        // );
        // delete _tokenApprovals[tokenId];

        // Get the account address
        address account = createAccount(tokenId);

        // Burn the account by sending the NFT to its own account address
        safeTransferFrom(owner, account, tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }
}
