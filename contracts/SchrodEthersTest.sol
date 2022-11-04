//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SchrodEthersCat.sol";

interface IMetadataManagerTest {
    function decode_Pool(uint _index, uint dna, uint rawr_modifier, uint collectionId) external view returns(uint);
}

contract SchrodEthersTest is SchrodEthersCat {

    using PRBMathSD59x18 for int;

    function testCollapse(uint tokenId, uint randomness) external onlyOwner {

        randomness = uint(keccak256(abi.encodePacked(randomness)));

        collapseWavefunction(tokenId, randomness);

    }

    function testMint(uint _amount) external {

        //require(_amount  <= maxMint, "Attempting to mint too many");

        uint tokenId = currentSupply;

        unchecked {

            require(tokenId + _amount <= maxSupply + 1, "Attempting to mint over max supply");

        }

        catStats memory baseCat =  catStats(0, 0, uint32(block.timestamp), 0, 1, 0, 0);

        for(uint i = 0; i < _amount;) {

            _mint(msg.sender, tokenId);

            catMap[tokenId] = baseCat;

            unchecked {

                tokenId++;
                ++i;
                
            }

        }

        currentSupply = tokenId;
    }

    function collapseWavefunctionTest(uint x) public view returns(uint, uint) {

        uint timePacked = block.timestamp - (x * 1 days);

        (uint a, uint b) = getChances(timePacked);

        return (a,b);

    }

    function getPools(uint tokenId) public view returns(uint[] memory) {

        uint[] memory pools = new uint[](numTraits);

        catStats memory cat = catMap[tokenId];

        for(uint i = 0; i < numTraits; i++) {

            pools[i] = IMetadataManagerTest(address(metadataManager)).decode_Pool(i, cat.kitDNA, cat.traitBonus, 1);

        }

        return pools;

    }

}