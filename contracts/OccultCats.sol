//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Libraries/PRBMathSD59x18.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";

import "./VRFConsumerBaseUpgradeable.sol";

struct catStats {

    uint128 DNA;
    uint8 traitBonus;
    uint32 timePacked;
    uint32 timeUnpacked;
    bool dead;
    uint8 boxType;
    uint40 leftover;

    uint256 extraSpace;

}

interface ShrodethersCat {

    function burn(uint tokenId, address owner) external;
    function catMap(uint) external returns(catStats memory);

}

contract OccultCats is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    using StringsUpgradeable for uint256;

    using PRBMathSD59x18 for int;

    uint constant price = 0.07 ether;

    uint constant maxMint = 5;

    uint constant maxSupply = 5000;

    uint constant numAttributes = 8;

    uint constant maxDuration = 7 days;

    int constant halfDeath = 1_742939800000000000;

    int constant rawrPower = 1_881286000000000000;

    int constant two = 2_000000000000000000;

    int constant eight = 8_000000000000000000;

    

    //mapping(uint => catStats) public catMap;
    mapping(uint => catStats) public catMap;

    mapping(bytes32 => uint) pendingmeasurements;

    struct traitPool {
        uint[] possibleTraits;
        uint thresh;

    }

    mapping(uint => traitPool[]) attributePool;

    mapping(address => bool) acceptedContracts;

    uint currentSupply;

    ShrodethersCat schrodethersCat;

    string constant baseURI = "";

    function initialize(address catAddress) public initializer {

        __Ownable_init();
        __ERC721_init("OccultCats", "OCCULT");
        schrodethersCat = ShrodethersCat(catAddress);
        
    }

    function Resurrect(uint tokenId) external {

        catStats memory catStat = schrodethersCat.catMap(tokenId);

        require(catStat.dead, "Cat isn't dead");

        schrodethersCat.burn(tokenId, msg.sender);

        _mint(msg.sender, tokenId);

        catStat.DNA = catStat.DNA / (10**16);

        catMap[tokenId] = catStat;

    }

    function tokenURI(uint tokenId) public view override returns(string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");


        //Cat has been put in a box
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";

    }

    function _authorizeUpgrade(address) internal view override onlyOwner {}


    function initialize_attributes(uint _attributeIndex, uint[][] calldata traits, uint[] calldata thresholds) external onlyOwner {
       
       require(attributePool[_attributeIndex][0].thresh == 0, "Attributes already set");

       require(traits.length == thresholds.length, "Arrays are not the same size");

        uint count = traits.length;

        for(uint i = 0; i < count;) {

            attributePool[_attributeIndex].push(traitPool(traits[i], thresholds[i]));

            unchecked {
                ++i;
            }

        }

    }

    function decode_kitDNA(uint _index, uint dna, uint rawr_modifier) internal view returns(uint trait){
        // TODO: INTEGRATE MODIFIER ON TRAIT RARITY
        dna = dna / (100 ** (_index));

        uint trait_pool_determiner = (dna % 100)+rawr_modifier;

        traitPool[] memory pools = attributePool[_index]; 

        for(uint i=0; i<pools.length;){
            if (trait_pool_determiner < pools[i].thresh) {
                // PICK RANDOM TRAIT
                trait = pools[i].possibleTraits[trait_pool_determiner % pools[i].possibleTraits.length];
                return trait; 
            }

            unchecked {
                ++i;
            }
        }
    }

    function observe_cat(uint _tokenID) public view returns(uint[numAttributes+2] memory genotype) {
        catStats memory cat = catMap[_tokenID];
        if (cat.boxType>0){
            // CAT STILL IN BOX 
            // DISPLAY BOX GRAPHIC
            genotype[0]= cat.boxType;
            return genotype;
        }
        
        // CAT OUTA THE BOX LET'S TAKE A PEEKY
        
        uint dna = cat.DNA;
        uint rawr_modifier = cat.traitBonus;
        
        genotype[1] = cat.dead ? 1:0;

        for(uint i=0; i<numAttributes;){
            genotype[i + 2]= decode_kitDNA(i, dna, rawr_modifier);

            unchecked {
                ++i;
            }
        }

        return genotype; 
    }


    function burn(uint tokenId, address owner) external {

        require(acceptedContracts[msg.sender], "Don't have permission");
        require(owner == ownerOf(tokenId), "Does not own kitty");

        require(_isApprovedOrOwner(msg.sender, tokenId), "");

        _burn(tokenId);

    }

    function setAcceptedContract(address _addr, bool _value) external onlyOwner {

        acceptedContracts[_addr] = _value;

    }
}
