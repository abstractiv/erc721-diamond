//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// typehash
bytes32 constant AGREEMENT_TYPEHASH = keccak256(
    "RentalAgreement(uint256 tokenId,uint256 pricePerUnit,address currency,uint64 unitOfTime,uint64 deadline,uint32 numberOfUnits)"
);
bytes32 constant MINTING_PERMISSION_TYPEHASH = keccak256(
    "MintingPermission(uint256 tokenId,address to,address currency,uint256 mintingPrice,string uri)"
);
bytes32 constant PAYBACK_TYPEHASH = keccak256(
    "RentalPayback(uint256 tokenId,uint256 paybackAmount,address renter,uint64 deadline)"
);

// roles hash
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

// layout position;
bytes32 constant ERC721_STORAGE_POSITION = keccak256(
    "diamond.standard.storage.erc721"
);
bytes32 constant CURRENCY_POSITION = keccak256(
    "diamond.standard.storage.underlying.currency"
);
bytes32 constant WITHDRAWAL_POSITION = keccak256(
    "diamond.standard.storage.withdrawal"
);
bytes32 constant ERC721_RENTAL_V4_STORAGE_POSTION = keccak256(
    "diamond.standard.storage.erc721.rental.v4"
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
struct RentalData {
    mapping(uint256 => Rental) rentals;
}

struct EIP712Data {
    bytes32 _CACHED_DOMAIN_SEPARATOR;
    uint256 _CACHED_CHAIN_ID;
    address _CACHED_THIS;
    bytes32 _HASHED_NAME;
    bytes32 _HASHED_VERSION;
    bytes32 _TYPE_HASH;
}

struct CurrencyData {
    bool supportsEther;
    mapping(address => bool) supportsCurrency;
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

struct RentalAgreement {
    uint256 tokenId;
    uint256 pricePerUnit;
    address currency;
    uint64 unitOfTime;
    uint64 deadline;
    uint32 numberOfUnits;
}

struct Rental {
    address owner;
    address renter;
    uint64 startingTimestamp;
    RentalAgreement agreement;
}

struct RentalPayback {
    uint256 tokenId;
    uint256 paybackAmount;
    address renter;
    uint64 deadline;
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

    function RentalStorage() internal pure returns (RentalData storage s) {
        bytes32 position = ERC721_RENTAL_V4_STORAGE_POSTION;
        assembly {
            s.slot := position
        }
    }

    function WithdrawalStorage()
        internal
        pure
        returns (WithdrawalData storage s)
    {
        bytes32 position = WITHDRAWAL_POSITION;
        assembly {
            s.slot := position
        }
    }

    function CurrencyStorage() internal pure returns (CurrencyData storage s) {
        bytes32 position = CURRENCY_POSITION;
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
