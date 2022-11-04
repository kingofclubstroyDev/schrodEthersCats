//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Libraries/PRBMathSD59x18.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./RrpRequesterV0Upgradeable.sol";
import "./structs/catStats.sol";
import "./structs/MetadataStruct.sol";

interface IMetadataManager {
    function getTokenUri(uint tokenId, MetadataStruct memory metadata, uint collectionId) external view returns(string memory);
    function makeUniqueCat(uint tokenId, uint randomness, uint collectionId) external;
}

interface IDeadCat {
    function DEATH(uint _experimentNumber, uint128 _DEADNA, address _beraved) external;
}


contract SchrodEthersCat is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable, RrpRequesterV0Upgradeable {

    using StringsUpgradeable for uint256;

    using PRBMathSD59x18 for int;

    IMetadataManager metadataManager;
    IDeadCat deadCat;

    string constant BaseURI = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
    string constant BaseBoxURI = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";

    uint constant collectionId = 1;

    uint8 constant numTraits = 12;

    uint constant uniqueCatChance = 200;

    uint constant price = 0.15 ether;

    uint constant maxMint = 6;

    uint constant maxSupply = 8000;

    //uint constant maxDuration = 7 days;
    int constant maxDuration = 604800_000000000000000000;
    //int constant maxDuration = 600_000000000000000000;

    //int constant halfDeath = 1_742939800000000000;
    int constant halfDeath = 1_548000000000000000;

    int constant rawrPower = 1_881286000000000000;

    int constant two = 2_000000000000000000;

    int constant eight = 8_000000000000000000;

    
    //mapping(uint => catStats) public catMap;
    mapping(uint => catStats) public catMap;

    mapping(bytes32 => uint) pendingmeasurements;

    mapping(address => bool) acceptedContracts;

    uint public currentSupply;

    // These can be set using setRequestParameters())
    address public airnode;
    bytes32 public endpointIdUint256;
    address public sponsorWallet;

    function initialize(address _metadataManagerAddress, address _deadCatAddress) public initializer {

        __Ownable_init();
        __ERC721_init("test", "test");

        metadataManager = IMetadataManager(_metadataManagerAddress);
        deadCat = IDeadCat(_deadCatAddress);

        //__RrpRequester_init(_airnodeRrp);
        //airnode = _airnode;
        //endpointIdUint256 = _endpointIdUint256;
        //sponsorWallet = _sponsorWallet;
        
    }


    function mint(uint _amount) external payable {

        require(_amount < maxMint, "Attempting to mint too many");

        uint tokenId = currentSupply;

        unchecked {

            require(msg.value == price * _amount, "Invalid value sent");

            require(tokenId + _amount <= maxSupply + 1, "Attempting to mint over max supply");

        }

        catStats memory baseCat =  catStats(0, 0, uint32(block.timestamp), 0, 1, 0, 0);

        for(uint i = 0; i < _amount;) {

            _mint(msg.sender, tokenId);

            catMap[tokenId] = baseCat;

            unchecked {

                ++tokenId;
                ++i;
                
            }

        }

        currentSupply = tokenId;

    }


    function RevealNFT(uint tokenId) internal {

        require(msg.sender == ownerOf(tokenId), "You don't own this cat, ya silly");
        catStats memory kittyCat = catMap[tokenId];

        require(kittyCat.timePacked > 0, "Your cat isn't even in the box"); 
        require(kittyCat.timeUnpacked == 0, "Your cat's wavefunction has already collapsed");

        catMap[tokenId].timeUnpacked = uint32(block.timestamp); 

        pendingmeasurements[airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            owner(),
            sponsorWallet,
            address(this),
            this.fulfillUint256.selector,
            ""
        )] = tokenId;
  
    }

    function RevealNFTs(uint[] calldata tokenIds) external {

        for(uint i = 0; i < tokenIds.length; i++) {

            RevealNFT(tokenIds[i]);

        }

    }

    function tokenURI(uint tokenId) public view override returns(string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        catStats memory kittyCat = catMap[tokenId];

        string memory uri;
        string memory baseName;
        string memory preName = "";
        string memory description;
        string memory attributes;
        bool hasTraits;

        if(kittyCat.boxType > 0) {

            //cat is in box in a super position between being alive and dead

            //TODO:
            uri = BaseBoxURI;
            baseName = "Experiment #";
            description = "Cat in a box";

            (uint deathChance, uint traitBonus) = getChances(kittyCat.timePacked);

            attributes = string(abi.encodePacked('{"display_type": "boost_percentage", "trait_type": "Chance of Death", "value": ', deathChance.toString(), '}, {"display_type": "boost_number", "trait_type": "Trait Bonus", "value": ', traitBonus.toString(), ', "max_value": 100 }, {"trait_type": "Living?", "value": "Yes and No" }'));

        } else {

            //cat is alive!

            //TODO: base description
            uri = BaseURI;
            attributes = '{"trait_type": "Living?", "value": "Yes"}';
            baseName = "Schrodethers Cat #";
            description = "Alive kitty cat";
            hasTraits = true;

        }

        return metadataManager.getTokenUri(tokenId, MetadataStruct(uri, preName, baseName, description, attributes, kittyCat.kitDNA, kittyCat.traitBonus, numTraits, hasTraits), collectionId);

    }

    function collapseWavefunction(uint tokenId, uint randomness) internal {
    
        catStats storage catStat = catMap[tokenId];

        catStat.timeUnpacked = uint32(block.timestamp);

        (uint chanceOfDeath, uint traitBonus) = getChances(uint(catStat.timePacked));
        
        uint death = (randomness / 10**75) % 101;

        catStat.traitBonus = uint8(traitBonus);

        if(!isUniqueCat(randomness, tokenId) && chanceOfDeath > death) {

            //You open the box to sadly see your cat is dead :(

            address owner = ownerOf(tokenId);
            delete catMap[tokenId];
            _burn(tokenId);
            deadCat.DEATH(tokenId, uint128(randomness), owner);
            return;

        }

        catStat.kitDNA = uint128(randomness);

        catStat.boxType = 0;

    }

    function getChances(uint timePacked) public view returns(uint, uint) {

        int timeInBox = int(block.timestamp - timePacked).fromInt();

        if(timeInBox > maxDuration) {

            timeInBox = maxDuration;
            
        }

        int percentTime = timeInBox.div(maxDuration).mul(eight);

        uint chanceOfDeath = uint((percentTime.pow(halfDeath).mul(two)).toInt());

        uint traitBonus = uint((percentTime.pow(rawrPower).mul(two)).toInt());

        return(chanceOfDeath, traitBonus);

    }

    // AirnodeRrp will call back with a response
    function fulfillUint256(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        uint256 randomness = abi.decode(data, (uint256));

        collapseWavefunction(pendingmeasurements[requestId], randomness);

        delete pendingmeasurements[requestId];
       
    }

    function _authorizeUpgrade(address) internal view override onlyOwner {}


    function burn(uint tokenId, address owner) external {

        require(acceptedContracts[msg.sender], "Don't have permission");
        require(owner == ownerOf(tokenId), "Does not own kitty");

        require(_isApprovedOrOwner(msg.sender, tokenId), "");

        _burn(tokenId);

        delete catMap[tokenId];

    }

    function isUniqueCat(uint randomness, uint tokenId) internal returns(bool) {

        if(randomness % uniqueCatChance == 0) {

            metadataManager.makeUniqueCat(tokenId, uint(keccak256(abi.encodePacked(randomness))), collectionId);

            return true;
            
        }

        return false;

    }

    function setAcceptedContract(address _addr, bool _value) external onlyOwner {

        acceptedContracts[_addr] = _value;

    }


    function setMetadataManager(address _metadataManager) external onlyOwner {

        metadataManager = IMetadataManager(_metadataManager);

    }

    // function setURI(string memory _baseURI, string memory _baseBoxURI) external onlyOwner {

    //     BaseURI = _baseURI;

    //     BaseBoxURI = _baseBoxURI;

    // }

    function withdraw() external onlyOwner {

        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Failure to withdraw");    

    }

}
