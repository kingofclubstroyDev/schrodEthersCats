//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Libraries/PRBMathSD59x18.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./structs/MetadataStruct.sol";

interface IMetadataManager {
    function getTokenUri(uint tokenId, MetadataStruct memory metadata, uint collectionId) external view returns(string memory);
}

contract DeadCat is ERC721, Ownable {

    using PRBMathSD59x18 for int;

    using Strings for uint;

    uint constant collectionId = 2;

    //TODO: move back to 7 days and set the proper values
    //int constant maxDuration = 604800_000000000000000000;
    int constant maxDuration = 600_000000000000000000;

    int constant halfDeath = 1_742939800000000000;

    int constant rawrPower = 1_881286000000000000;

    int constant two = 2_000000000000000000;

    int constant eight = 8_000000000000000000;

    address immutable schrodethersCat;

    IMetadataManager metadataManager;

    string public baseURI;

    struct DeadCatStats {
        uint128 DEADNA;
        uint128 deathTime;
    }

    mapping(uint => DeadCatStats) public deadCatMap;

    mapping(address => bool) canDesecrate;

    uint public raptureTime;

    constructor(address _schrodethersCatAddress, address _metadataManagerAddress, string memory _uri) ERC721("Dead Cat", "DEAD") {

        schrodethersCat = _schrodethersCatAddress;
        metadataManager = IMetadataManager(_metadataManagerAddress);
        baseURI = _uri;

    }

    function DEATH(uint _experimentNumber, uint128 _DEADNA, address _beraved) external {

        require(msg.sender == schrodethersCat, "You can't just kill a cat");

        _mint(_beraved, _experimentNumber);

        deadCatMap[_experimentNumber] = DeadCatStats(_DEADNA, uint128(block.timestamp));

    }

    function Desecrate(uint _experimentNumber, address _beraved) external {

        require(canDesecrate[msg.sender]);
        require(ownerOf(_experimentNumber) == _beraved, "Not owner");

        _isApprovedOrOwner(msg.sender, _experimentNumber);

        delete deadCatMap[_experimentNumber];

        _burn(_experimentNumber);

    }

    function tokenURI(uint tokenId) public view override returns(string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        DeadCatStats memory deadCat = deadCatMap[tokenId];

        string memory baseName = "#";
        string memory preName = "The Late ";
        string memory description = "Unfortunate soul... \\n Excised from this mortal coil \\n May death bring repose?";
        string memory attributes = '{"trait_type": "Living?", "value": "No"}';

        if(raptureTime > 0) {

            //The rapture has started

            uint decayStart = deadCat.deathTime;

            if(decayStart < raptureTime) {
                decayStart = raptureTime;
            }

            (uint decay, uint occultBonus) = getChances(decayStart);

            attributes = string(abi.encodePacked(attributes, ', {"display_type": "boost_percentage", "trait_type": "Decay", "value": ', decay.toString(), '}, {"display_type": "boost_number", "trait_type": "Trait Bonus", "value": ', occultBonus.toString(), ' }'));

        }

        return metadataManager.getTokenUri(tokenId, MetadataStruct(baseURI, preName, baseName, description, attributes, deadCat.DEADNA, 0, 0, false), collectionId);

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

    function InitiateRapture() external onlyOwner {

        require(raptureTime == 0, "Rapture has already started");

        raptureTime = block.timestamp;

    }

    function setCanDesecrate(address _desecrator, bool _value) external onlyOwner {
        canDesecrate[_desecrator] = _value;
    }


}