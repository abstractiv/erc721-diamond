// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Values describing mint phases
enum MintPhase {
    CLOSED,
    TEAM,
    ALLOWLIST,
    WAITLIST,
    PUBLIC
}

struct TokenData {

	 // Token name
    string _name;

    // Token symbol
    string _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;

    // Mapping owner address to token count
    mapping(address => uint256) _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;

    // URI for metadata
    string _baseTokenURI;

    // Max number of tokens
    uint256 _maxSupply;

    // The address receiving mint revenue
    address payable _beneficiary;

    // Mapping for admin
    mapping(address => bool) _admins;

    // Current mint phase
    MintPhase _mintPhase;

    // Paused flag
    bool _paused;

}


// layout position;
bytes32 constant ERC721_STORAGE_POSITION = keccak256(
    "diamond.standard.storage.erc721"
);

library LibERC721Storage {

    function tokenStorage() internal pure returns (TokenData storage s) {
        bytes32 position = ERC721_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

}
