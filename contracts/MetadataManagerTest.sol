//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./MetadataManager.sol";

contract MetadataManagerTest is MetadataManager {

    function decode_Pool(uint _index, uint dna, uint rawr_modifier, uint collectionId) external view returns(uint) {
       
        dna = dna / (100 ** (_index));

        uint trait_pool_determiner = (dna % 100) + rawr_modifier;

        traitPool[] memory pools = attributePool[collectionId][_index];

        for(uint i=0; i < pools.length;){

            if (trait_pool_determiner < pools[i].thresh) {

                return i;
                
            }

            unchecked {
                ++i;
            }
        }

        return 0;
    }

}