//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// typehash
bytes32 constant MINTING_PERMISSION_TYPEHASH = keccak256(
    "MintingPermission(uint256 tokenId,address to,address currency,uint256 mintingPrice,string uri)"
);

// roles hash
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

// layout position;
bytes32 constant ERC721_STORAGE_POSITION = keccak256(
    "diamond.standard.storage.erc721"
);
bytes32 constant DIAMOND_STORAGE_POSITION = keccak256(
    "diamond.standard.diamond.storage"
);
bytes32 constant EIP712_STORAGE_POSITION = keccak256(
    "diamond.standard.diamond.storage.eip712.storage"
);
bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256(
    "diamond.standard.storage.access.control"
);

struct FacetAddressAndSelectorPosition {
    address facetAddress;
    uint16 selectorPosition;
}
struct DiamondStorage {
    mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
    bytes4[] selectors;
    mapping(bytes4 => bool) supportedInterfaces;
    address contractOwner;
}

struct ERC721Data {
    string name;
    string symbol;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    mapping(uint256 => string) tokenURIs;
}

struct EIP712Data {
    bytes32 _CACHED_DOMAIN_SEPARATOR;
    uint256 _CACHED_CHAIN_ID;
    address _CACHED_THIS;
    bytes32 _HASHED_NAME;
    bytes32 _HASHED_VERSION;
    bytes32 _TYPE_HASH;
}

struct WithdrawalData {
    mapping(address => uint256) ethPending;
    mapping(address => mapping(address => uint256)) erc20Pending;
}

struct MintingPermission {
    uint256 tokenId;
    address to;
    address currency;
    uint256 mintingPrice;
    string uri;
    bytes signature;
}

struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

struct AccessControlData {
    mapping(bytes32 => RoleData) roles;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (DiamondStorage storage s) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function ERC721Storage() internal pure returns (ERC721Data storage s) {
        bytes32 position = ERC721_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function EIP712Storage() internal pure returns (EIP712Data storage s) {
        bytes32 position = EIP712_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function AccessControlStorage()
        internal
        pure
        returns (AccessControlData storage s)
    {
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

contract Modifiers is Context {
    function contractOwner() internal view returns (address) {
        return LibAppStorage.diamondStorage().contractOwner;
    }

    modifier onlyRole(bytes32 role) {
        require(
            LibAppStorage.AccessControlStorage().roles[role].members[
                _msgSender()
            ]
        );
        _;
    }
}
