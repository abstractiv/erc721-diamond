//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "./../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "./AccessControlFacet.sol";
import "./../libraries/UsingEIP712.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ERC721URIStorage is UsingEIP712 {
    using SafeERC20 for IERC20;
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function storageLayout() internal pure returns (ERC721Data storage) {
        return LibAppStorage.ERC721Storage();
    }

    function name() external view returns (string memory) {
        return storageLayout().name;
    }

    function symbol() external view returns (string memory) {
        return storageLayout().symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = storageLayout().tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return _tokenURI;
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return storageLayout().balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = storageLayout().owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return storageLayout().tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return storageLayout().operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _baseURI() internal view returns (string memory) {
        return "";
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return storageLayout().owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        ERC721Data storage s = storageLayout();
        _beforeTokenTransfer(address(0), to, tokenId);

        s.balances[to] += 1;
        s.owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        ERC721Data storage s = storageLayout();
        s.balances[owner] -= 1;
        delete s.owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        ERC721Data storage s = storageLayout();
        s.balances[from] -= 1;
        s.balances[to] += 1;
        s.owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        storageLayout().tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        storageLayout().operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        storageLayout().tokenURIs[tokenId] = _tokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        RentalData storage s = LibAppStorage.RentalStorage();
        require(
            s.rentals[tokenId].owner == address(0) &&
                s.rentals[tokenId].renter == address(0)
        );
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {}

    function mint(
        address to,
        uint256 tokenId,
        string memory _tokenURI
    ) external onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function mintWithPermit(MintingPermission calldata permission)
        external
        returns (uint256)
    {
        // CHECKS
        AccessControlData storage acd = LibAppStorage.AccessControlStorage();
        address signer = _verifyMintingPermission(permission);
        require(acd.roles[MINTER_ROLE].members[signer], "Invalid signature");
        CurrencyData storage cd = LibAppStorage.CurrencyStorage();
        require(
            permission.currency != address(0) &&
                cd.supportsCurrency[permission.currency],
            "Currency not supported"
        );

        require(
            IERC20(permission.currency).allowance(msg.sender, address(this)) >=
                permission.mintingPrice,
            "Allowance not enough"
        );
        IERC20 currency = IERC20(permission.currency);

        // EFFECTS
        WithdrawalData storage wd = LibAppStorage.WithdrawalStorage();
        uint256 before = wd.erc20Pending[address(currency)][contractOwner()];
        wd.erc20Pending[address(currency)][contractOwner()] = before.add(
            permission.mintingPrice
        );
        _safeMint(signer, permission.tokenId);
        _setTokenURI(permission.tokenId, permission.uri);
        _transfer(signer, permission.to, permission.tokenId);

        // INTERACTIONS
        currency.safeTransferFrom(
            msg.sender,
            address(this),
            permission.mintingPrice
        );
        assert(ownerOf(permission.tokenId) == permission.to);
        return permission.tokenId;
    }

    function mintPermitWithETH(MintingPermission calldata permission)
        external
        payable
        returns (uint256)
    {
        AccessControlData storage acd = LibAppStorage.AccessControlStorage();
        address signer = _verifyMintingPermission(permission);
        require(acd.roles[MINTER_ROLE].members[signer], "Invalid signature");
        CurrencyData storage cd = LibAppStorage.CurrencyStorage();
        require(
            permission.currency == address(0) && cd.supportsEther,
            "Currency not supported"
        );

        require(msg.value >= permission.mintingPrice, "Value not enough");

        // EFFECTS
        WithdrawalData storage wd = LibAppStorage.WithdrawalStorage();
        uint256 before = wd.ethPending[contractOwner()];
        wd.ethPending[contractOwner()] = before.add(permission.mintingPrice);
        _safeMint(signer, permission.tokenId);
        _setTokenURI(permission.tokenId, permission.uri);
        _transfer(signer, permission.to, permission.tokenId);

        // INTERACTIONS
        if (msg.value > permission.mintingPrice) {
            payable(msg.sender).transfer(
                msg.value.sub(permission.mintingPrice)
            );
        }

        assert(ownerOf(permission.tokenId) == permission.to);
        return permission.tokenId;
    }

    function _verifyMintingPermission(MintingPermission calldata permission)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashMintingPermission(permission);
        return ECDSA.recover(digest, permission.signature);
    }

    function _hashMintingPermission(MintingPermission calldata permission)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MINTING_PERMISSION_TYPEHASH,
                        permission.tokenId,
                        permission.to,
                        permission.currency,
                        permission.mintingPrice,
                        keccak256(bytes(permission.uri))
                    )
                )
            );
    }
}

// contract ERC721Facet is UsingEIP712, DiamondERC721 {
//     using SafeERC20 for IERC20;
//     using SafeMath for uint256;
// function mint(
//         address to,
//         uint256 tokenId,
//         string memory _tokenURI
//     ) external onlyRole(MINTER_ROLE) {
//         _safeMint(to, tokenId);
//         _setTokenURI(tokenId, _tokenURI);
//     }

//     function mintWithPermit(MintingPermission calldata permission)
//         external
//         returns (uint256)
//     {
//         // CHECKS
//         AccessControlData storage acd = LibAppStorage.AccessControlStorage();
//         address signer = _verifyMintingPermission(permission);
//         require(acd.roles[MINTER_ROLE].members[signer], "Invalid signature");
//         CurrencyData storage cd = LibAppStorage.CurrencyStorage();
//         require(
//             permission.currency != address(0) &&
//                 cd.supportsCurrency[permission.currency],
//             "Currency not supported"
//         );

//         require(
//             IERC20(permission.currency).allowance(msg.sender, address(this)) >=
//                 permission.mintingPrice,
//             "Allowance not enough"
//         );
//         IERC20 currency = IERC20(permission.currency);

//         // EFFECTS
//         WithdrawalData storage wd = LibAppStorage.WithdrawalStorage();
//         uint256 before = wd.erc20Pending[address(currency)][contractOwner()];
//         wd.erc20Pending[address(currency)][contractOwner()] = before.add(
//             permission.mintingPrice
//         );
//         _safeMint(signer, permission.tokenId);
//         _setTokenURI(permission.tokenId, permission.uri);
//         _transfer(signer, permission.to, permission.tokenId);

//         // INTERACTIONS
//         currency.safeTransferFrom(
//             msg.sender,
//             address(this),
//             permission.mintingPrice
//         );
//         assert(ownerOf(permission.tokenId) == permission.to);
//         return permission.tokenId;
//     }

//     function mintPermitWithETH(MintingPermission calldata permission)
//         external
//         payable
//         returns (uint256)
//     {
//         AccessControlData storage acd = LibAppStorage.AccessControlStorage();
//         address signer = _verifyMintingPermission(permission);
//         require(acd.roles[MINTER_ROLE].members[signer], "Invalid signature");
//         CurrencyData storage cd = LibAppStorage.CurrencyStorage();
//         require(
//             permission.currency == address(0) && cd.supportsEther,
//             "Currency not supported"
//         );

//         require(msg.value >= permission.mintingPrice, "Value not enough");

//         // EFFECTS
//         WithdrawalData storage wd = LibAppStorage.WithdrawalStorage();
//         uint256 before = wd.ethPending[contractOwner()];
//         wd.ethPending[contractOwner()] = before.add(permission.mintingPrice);
//         _safeMint(signer, permission.tokenId);
//         _setTokenURI(permission.tokenId, permission.uri);
//         _transfer(signer, permission.to, permission.tokenId);

//         // INTERACTIONS
//         if (msg.value > permission.mintingPrice) {
//             payable(msg.sender).transfer(
//                 msg.value.sub(permission.mintingPrice)
//             );
//         }

//         assert(ownerOf(permission.tokenId) == permission.to);
//         return permission.tokenId;
//     }

//     function _verifyMintingPermission(MintingPermission calldata permission)
//         internal
//         view
//         returns (address)
//     {
//         bytes32 digest = _hashMintingPermission(permission);
//         return ECDSA.recover(digest, permission.signature);
//     }

//     function _hashMintingPermission(MintingPermission calldata permission)
//         internal
//         view
//         returns (bytes32)
//     {
//         return
//             _hashTypedDataV4(
//                 keccak256(
//                     abi.encode(
//                         MINTING_PERMISSION_TYPEHASH,
//                         permission.tokenId,
//                         permission.to,
//                         permission.currency,
//                         permission.mintingPrice,
//                         keccak256(bytes(permission.uri))
//                     )
//                 )
//             );
//     }
// }
