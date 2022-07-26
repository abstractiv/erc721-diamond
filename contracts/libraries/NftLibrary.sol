pragma solidity ^0.8.0;

import "../interfaces/IERC721Custom.sol";
import { MintPhase } from "./LibERC721Storage.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

library NftLibrary {

    // TODO change to diamond storage:
    // https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9
    // https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb

    struct CollectionData {
        uint256[5] pricePerMintPhase;
        uint256[5] maxPerMintPhase;

        // Merkle trees
        bytes32[5] merkleRoots;

        // Mappings
        mapping(address => bool) isMintedList;
        mapping(address => bool) isMintedPublic;
    }

    event ChangedMintPhase(MintPhase _mintPhase);
    event ChangedPrice(uint256 _mintPhase, uint256 _price);
    event ChangedMaxQuantity(uint256 _mintPhase, uint256 _qty);
    event ChangedMerkleRoot(uint256 _mintPhase, bytes32 _newMerkleRoot);

    /**
     * @dev Ensure the caller is an externally owned address (EOA)
     */
    function isHumanUser() public view returns (bool) {
        return tx.origin == msg.sender;
    }

    function getHasMinted(
        CollectionData storage collectionData,
        address _address,
        uint256 _uintMintPhase
    ) public view returns (bool) {
        if (MintPhase(_uintMintPhase) == MintPhase.ALLOWLIST || MintPhase(_uintMintPhase) == MintPhase.WAITLIST) {
            return collectionData.isMintedList[_address];
        } else {
            return collectionData.isMintedPublic[_address];
        }
    }


    function setMintPhase(uint256 _uintMintPhase) public returns (MintPhase) {
        // _uintMintPhase -> 0: MintStatus.CLOSED, 1: MintStatus.TEAM, 2: MintStatus.ALLOWLIST, 3: MintStatus.WAITLIST, 4: MintStatus.PUBLIC
        if (_uintMintPhase < 0 && _uintMintPhase > 3) revert IERC721Custom.MintPhaseNotFound(_uintMintPhase);
        MintPhase mintPhase = MintPhase(_uintMintPhase);
        emit ChangedMintPhase(mintPhase);
        return mintPhase;
    }


    function verifyMintEligibility(
        CollectionData storage collectionData,
        MintPhase mintPhase,
        uint256 totalSupply,
        uint256 maxSupply,
        uint256 _qty,
        bytes32[] calldata _proof
    ) public {
        // Check if mint open
        if (mintPhase == MintPhase.CLOSED) revert IERC721Custom.MintingClosed();

        // Check if enough left in max supply
        if (totalSupply + _qty > maxSupply) revert IERC721Custom.InsufficientMaxQuantity();

        // Check if minting beyond allocated amount
        if (_qty <= 0 && _qty > collectionData.maxPerMintPhase[uint256(mintPhase)]) revert IERC721Custom.QuantityError();

        if (mintPhase != MintPhase.TEAM) {
            // Check if is human user if not minting in TEAM mint phase
            if (!isHumanUser()) revert IERC721Custom.NonHumanSender();

            // Check price if not minting in TEAM mint phase
            if (msg.value < collectionData.pricePerMintPhase[uint256(mintPhase)] * _qty) revert IERC721Custom.InsufficientMintEth(collectionData.pricePerMintPhase[uint256(mintPhase)] * _qty);
        }

        // Check if in the mint phases' respective list
        if (mintPhase != MintPhase.PUBLIC) {
            _checkProof(collectionData.merkleRoots[uint256(mintPhase)], _proof);
        }

        // Check if address has already minted
        if (mintPhase == MintPhase.TEAM || mintPhase == MintPhase.ALLOWLIST || mintPhase == MintPhase.WAITLIST) {
            if (collectionData.isMintedList[msg.sender]) revert IERC721Custom.AlreadyMinted();
            collectionData.isMintedList[msg.sender] = true;
        } else {
            if (collectionData.isMintedPublic[msg.sender]) revert IERC721Custom.AlreadyMinted();
            collectionData.isMintedPublic[msg.sender] = true;
        }
    }


    /**
     * @dev Given Merkle root, validate address against Merkle proof
     */
    function _checkProof(bytes32 _merkleRoot, bytes32[] calldata _proof) public view {
        if ( ! MerkleProofUpgradeable.verify(_proof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))) )
            revert IERC721Custom.AddressNotOnList();
    }


    // Set different merkle roots for different phases
    function setMerkleRoot(CollectionData storage collectionData, bytes32 _merkleRoot, uint256 _uintMintPhase) public {
        // _uintMintPhase -> 0: MintStatus.CLOSED, 1: MintStatus.TEAM, 2: MintStatus.ALLOWLIST, 3: MintStatus.WAITLIST, 4: MintStatus.PUBLIC
        if (_uintMintPhase < 0 || _uintMintPhase > 4) revert IERC721Custom.MintPhaseNotFound(_uintMintPhase);
        collectionData.merkleRoots[_uintMintPhase] = _merkleRoot;
        emit ChangedMerkleRoot(_uintMintPhase, _merkleRoot);
    }

    function setPrice(CollectionData storage collectionData, uint256 _uintMintPhase, uint256 _price) public {
        if (_price < 0) revert IERC721Custom.InvalidPrice();
        collectionData.pricePerMintPhase[_uintMintPhase] = _price;
        emit ChangedPrice(_uintMintPhase, _price);
    }

    function setMaxPerMintPhase(CollectionData storage collectionData, uint256 _uintMintPhase, uint256 _qty, uint256 _maxSupply) public {
        if (_qty < 0 || _qty > _maxSupply) revert IERC721Custom.QuantityError();
        collectionData.maxPerMintPhase[_uintMintPhase] = _qty;
        emit ChangedMaxQuantity(_uintMintPhase, _qty);
    }


    function withdraw(address beneficiary, address contractAddress) public {
        if (beneficiary == address(0)) revert IERC721Custom.BeneficiaryAddressNotSet();
        if (contractAddress.balance == 0) revert IERC721Custom.EthBalanceZero();
        payable(beneficiary).transfer(contractAddress.balance);
    }

}
