// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/IERC721Custom.sol";
import "../libraries/NftLibrary.sol";

contract Catas is
IERC721Custom,
ERC721EnumerableUpgradeable,
OwnableUpgradeable,
ReentrancyGuardUpgradeable,
UUPSUpgradeable
{
    // =============================
    //       Collection Data
    // =============================

    // Params
    string private baseTokenURI;
    uint256 public maxSupply;

    // The address receiving mint revenue.
    address payable public beneficiary;

    // Mappings
    mapping(address => bool) private admins;


    // Current mint phase
    MintPhase public mintPhase;
    bool public paused;

    using NftLibrary for NftLibrary.CollectionData;
    NftLibrary.CollectionData collectionData;

    function initialize() public initializer {
        __ERC721_init("Catas", "CATAS");
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        maxSupply = 500;
        mintPhase = MintPhase.CLOSED;
        paused = false;

        collectionData.pricePerMintPhase = [0, 0, 0.0001 ether, 0.0001 ether, 0.0005 ether];
        collectionData.maxPerMintPhase = [0, 1, 1, 1, 2];
    }



    // =============================
    //          Modifiers
    // =============================
    modifier adminOrOwner() {
        if ( msg.sender != owner() && !admins[msg.sender] ) revert Unauthorized();
        _;
    }


    // =============================
    //            Mint
    // =============================
    function mint(
        uint256 _qty,
        bytes32[] calldata _proof
    ) external payable nonReentrant {
        collectionData.verifyMintEligibility(
            mintPhase,
            totalSupply(),
            maxSupply,
            _qty,
            _proof
        );
        _safeMint(msg.sender, _qty);
        emit Mint(msg.sender, _qty, msg.value);
    }




    // =============================
    //           Admin
    // =============================
    function upsertAdmin(address _admin, bool _status) external adminOrOwner {
        admins[_admin] = _status;
    }


    // Getters
    function baseURI() external returns (string memory) {
        return baseTokenURI;
    }

    function tokenExists(uint256 _id) public view returns (bool) {
        return _exists(_id);
    }

//    function getHasMinted(address _address, uint256 _uintMintPhase) public view returns (bool) {
//        return collectionData.getHasMinted(_address, _uintMintPhase);
//    }


    // Setters
    function setBaseURI(string memory _baseTokenURI) external adminOrOwner {
        baseTokenURI = _baseTokenURI;
        emit ChangedBaseURI(_baseTokenURI);
    }

    function setMintPhase(uint256 _uintMintPhase) external adminOrOwner {
        mintPhase = NftLibrary.setMintPhase(_uintMintPhase);
    }

    // Set different merkle roots for different phases
    function setMerkleRoot(bytes32 _merkleRoot, uint256 _uintMintPhase) external adminOrOwner {
        collectionData.setMerkleRoot(_merkleRoot, _uintMintPhase);
    }


    function setMaxQuantity(uint256 _uintMintPhase, uint256 _qty) external adminOrOwner {
        collectionData.setMaxPerMintPhase(_uintMintPhase, _qty, maxSupply);
    }


    function setPrice(uint256 _uintMintPhase, uint256 _price) external adminOrOwner {
        collectionData.setPrice(_uintMintPhase, _price);
    }


    function setPaused(bool _pausedState) external adminOrOwner {
        paused = _pausedState;
    }

    /**
     * @dev See {INftProject-setBeneficiary}.
     */
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    // Withdraw ETH
    function withdraw() external payable nonReentrant onlyOwner {
        NftLibrary.withdraw(beneficiary, address(this));
    }


    // =============================
    //           IERC165
    // =============================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721EnumerableUpgradeable)
    returns (bool)
    {
        return
        ERC721Upgradeable.supportsInterface(interfaceId)
        || ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ;
    }


    // =============================
    //       UUPSUpgradeable
    // =============================

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}. Stops unauthorized upgrades
     */
    function _authorizeUpgrade(address) internal view override onlyOwner {} // solhint-disable no-empty-blocks


    // =============================
    //          Fallback
    // =============================
    // Receive fallback function, called when no calldata is present regardless of if ether was received
    receive() external payable {}
}