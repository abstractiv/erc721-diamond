//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./../libraries/UsingEIP712.sol";
import "./../libraries/LibDiamond.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

contract ERC721Init is UsingEIP712 {
    struct Init {
        string domainName;
        string version;
    }

    function init(Init calldata data) external {
        EIP712Data storage eip = LibAppStorage.EIP712Storage();

        bytes32 hashedName = keccak256(bytes(data.domainName));
        bytes32 hashedVersion = keccak256(bytes(data.version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        eip._HASHED_NAME = hashedName;
        eip._HASHED_VERSION = hashedVersion;
        eip._CACHED_CHAIN_ID = block.chainid;
        eip._CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        eip._CACHED_THIS = address(this);
        eip._TYPE_HASH = typeHash;
    }
}
