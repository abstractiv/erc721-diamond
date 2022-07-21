// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10 <0.9.0;

/**
 * @dev Interface of a Sendai compliant contract.
 */
interface INftProject {
    // Thrown when minting with minting not open.
    error MintingClosed();

    // Thrown when minting phase uint256 is out of bounds for enum.
    error MintPhaseNotFound(uint256 mintPhase);

    // Thrown when minting when trying to mint more than max supply.
    error InsufficientMaxQuantity();

    // Thrown when trying to mint greater than allowed per mint phase or equal to/less than 0.
    error QuantityError();

    // Thrown when address has already minted; Address limited to minting only once.
    error AlreadyMinted();

    // Thrown when merkle proof for address is invalid.
    error AddressNotOnList();

    // Thrown when price does not match mint price.
    error InsufficientMintEth(uint256 expectedEth);

    // Thrown when minting when there are no more left.
    error SoldOut();

    // Thrown when using a contract vs an externally owned address (EOA)
    error NonHumanSender();

    // Thrown when not passing owner and/or admin check
    error Unauthorized();

    // Thrown when beneficiary address to withdraw to is not set.
    error BeneficiaryAddressNotSet();

    // Thrown when withdrawing on a 0 eth balance
    error EthBalanceZero();

    // Thrown when setting price to less than 0
    error InvalidPrice();

    // Values describing mint phases.
    enum MintPhase {
        CLOSED,
        TEAM,
        ALLOWLIST,
        WAITLIST,
        PUBLIC
    }

    /**
     * @dev Emitted when mint phase is changed.
     */
    event ChangedMintPhase(MintPhase _mintPhase);

    /**
     * @dev Emitted when token base URI has changed.
     */
    event ChangedBaseURI(string _newURI);

    /**
     * @dev Emitted when a buyer is refunded.
     */
    event Refund(address indexed _buyer, uint256 _amount);

    /**
     * @dev Emitted when a Merkle root has changed.
     */
    event ChangedMerkleRoot(uint256 _mintPhase, bytes32 _newMerkleRoot);

    /**
     * @dev Emitted when price for a mint phase has changed.
     */
    event ChangedPrice(uint256 _mintPhase, uint256 _price);

    /**
     * @dev Emitted when max mintable quantity for a mint phase has changed.
     */
    event ChangedMaxQuantity(uint256 _mintPhase, uint256 _qty);

    /**
     * @dev Emitted on all purchases of non-zero amount.
     */
    event Mint(address _minter, uint256 _qty, uint256 _ethAmount);





    /**
     * @dev Mints Rigs for team.
     *
     * _quantity - the number of Rigs to mint
     * _proof - merkle leaf proof for team member's address
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - quantity must not be zero
     * - contract mint phase must be `MintPhase.PUBLIC`
     */
//    function teamMint(uint256 _quantity, bytes32[] calldata _proof) external;

    /**
     * @dev Mints Rigs from a whitelist.
     *
     * quantity - the number of Rigs to mint
     * freeAllowance - the number of free Rigs allocated to minter address
     * paidAllowance - the number of paid Rigs allocated to minter address
     * proof - merkle proof proving minter address has said `freeAllowance` and `paidAllowance`
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - quantity must not be zero
     * - proof must be valid and correspond to `msg.sender`, `freeAllowance`, and `paidAllowance`
     * - contract mint phase must be `MintPhase.ALLOWLIST` or `MintPhase.WAITLIST`
     */
    function mint(
        uint256 _quantity,
        bytes32[] calldata _proof
    ) external payable;

    /**
     * @dev Sets mint phase.
     *
     * mintPhase - the new mint phase to set
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - `_uintMintPhase` must correspond to one of enum `MintPhase`
     */
    function setMintPhase(uint256 _uintMintPhase) external;

    /**
     * @dev Sets mint phase beneficiary.
     *
     * beneficiary - the address to set as beneficiary
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setBeneficiary(address payable _beneficiary) external;

    /**
     * @dev Sets the token URI template.
     *
     * uriTemplate - the new URI template
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setBaseURI(string memory _baseTokenURI) external;

    /**
     * @dev Returns contract URI for storefront-level metadata.
     */
    function baseURI() external returns (string memory);


    /**
     * @dev Sets the paused state for contract. This affects:
     *
     * Requirements:
     *
     * - `msg.sender` must be contract admin or owner
     */
    function setPaused(bool _pausedState) external;


    function setPrice(uint256 _mintPhase, uint256 _price) external;

}