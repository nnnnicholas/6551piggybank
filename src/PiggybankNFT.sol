// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "reference/src/lib/ERC6551AccountLib.sol";
import "reference/src/interfaces/IERC6551Registry.sol";

/// @title PiggybankNFT
/// @notice An NFT piggybank that accepts ETH.
/// @dev An ERC-721 NFT piggybank implementation.
/// @author nnnnicholas
contract PiggybankNFT is ERC721 {
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
    }

    function burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ownerOf(tokenId);

        // Clear approvals
        removeTokenApprovals(tokenId);

        // Get the account address
        address account = getAccount(tokenId);

        // Burn the account by sending the NFT to its own account address
        transferFrom(owner, account, tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }
}
