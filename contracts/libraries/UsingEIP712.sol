//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract UsingEIP712 is Modifiers {
    function _domainSeparatorV4() internal view returns (bytes32) {
        EIP712Data storage s = LibAppStorage.EIP712Storage();
        if (
            address(this) == s._CACHED_THIS &&
            block.chainid == s._CACHED_CHAIN_ID
        ) {
            return s._CACHED_DOMAIN_SEPARATOR;
        } else {
            return
                _buildDomainSeparator(
                    s._TYPE_HASH,
                    s._HASHED_NAME,
                    s._HASHED_VERSION
                );
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}
