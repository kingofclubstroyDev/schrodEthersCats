//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./structs/catStats.sol";

interface ISchrodethersCats {

    function ownerOf(uint tokenId) external view returns(address);

    function getChances(uint timePacked) external view returns(uint, uint);

    function currentSupply() external view returns(uint);

}

interface IDeadCat {
    function IsRapture() external view returns(bool);
    function getChances(uint timePacked) external view returns(uint, uint);
}

contract MetadataManagerOld is Ownable {

    using Strings for uint;

    event TextChanged(uint indexed tokenId);

    ISchrodethersCats immutable schrodethersCats;
    IDeadCat immutable deadCat;
    
    string constant boxURI = "ipfs://bafybeidln2zcrzdermvbtiqmiqa5xfq6mqkyvu2snfrm5wbwhahcztc2bm";
    string constant unboxedURI = "ipfs://bafybeibracoh6zxki4cim4quagksabsqtdlvo34i6gq33cq6mddug77iji/ionizedKey.gif";
    string constant deadURI = "ipfs://bafybeibracoh6zxki4cim4quagksabsqtdlvo34i6gq33cq6mddug77iji/stableKey.gif";
    string public ipfsURI;

    uint constant numAttributes = 3;

    //TODO: change this to 0.02 ether
    uint constant textChangeCost = 0.000001 ether;
    bool public canChangeText = false;

    struct traitPool {
        uint8[] possibleTraits;
        uint8[] rarities;
        uint thresh;
    }

    mapping(uint => traitPool[]) public attributePool;

    mapping(uint => string) public propertyNames;

    mapping(uint => mapping(uint => string)) public traitNames;

    uint[] isIpfs;

    //TODO: change
    string constant baseDescription = "Kitty cat";

    string constant baseDeadDescription = "Dead Kitty Cat";

    string constant baseName = "Schrodether's Cat #";

    mapping(uint => string) public catNames;
    mapping(string => bool) nameTaken;
    mapping(uint => string) public catDescriptions;

    struct UniqueCat {
        string ipfs;
        string attributes;
        string name;
        string description;
    }

    UniqueCat[] remainingUniqueCats;

    mapping(uint => UniqueCat) uniqueCats;

    mapping(bytes32 => UniqueCat) pendingmeasurements;

    address uniqueCatContract;

    // These can be set using setRequestParameters())
    address public airnode;
    bytes32 public endpointIdUint256;
    address public sponsorWallet;


    constructor(address _schrodethersCats, address _deadCat) {
        schrodethersCats = ISchrodethersCats(_schrodethersCats);
        deadCat = IDeadCat(_deadCat);

    }

    function getTokenUri(uint tokenId, catStats memory stats) external view returns(string memory) {

        string memory name = catNames[tokenId];

        string memory description = catDescriptions[tokenId];

        if(bytes(name).length == 0) {
            name = string(abi.encodePacked(baseName, tokenId.toString()));
        }

        if(bytes(description).length == 0) {
            description = baseDescription;
        }

        if(bytes(uniqueCats[tokenId].ipfs).length > 0) {

            UniqueCat memory specialCat = uniqueCats[tokenId];

            return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "', specialCat.name,'", "description": "', specialCat.description, '", "image": "',
                                specialCat.ipfs,
                                '"', specialCat.attributes, '}')
                        )
                    )
                )
            );

        }

        string memory baseURI;

        if(stats.boxType > 0) {
            //cat is in box
            //get chances
            (uint deathChance, uint traitBonus) = schrodethersCats.getChances(stats.timePacked);

            return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "', name,'", "description": "', description, '", "image": "',
                                boxURI,
                                '","attributes": [{"display_type": "boost_percentage", "trait_type": "Chance of Death", "value": ', deathChance.toString(), '}, {"display_type": "boost_number", "trait_type": "Trait Bonus", "value": ', traitBonus.toString(), ', "max_value": 100 }, {"trait_type": "Living?", "value": "Yes and No" } ]}'
                            )
                        )
                    )
                )
            );
        }

       

        baseURI = unboxedURI;
        // if(getIsIpfs(tokenId)) {

        //     baseURI = ipfsURI;
        // }

        //todo: add back
        // baseURI = string(abi.encodePacked(baseURI, tokenId.toString()));


        //uint[] memory genome = observe_cat(stats.DNA, stats.traitBonus, stats.boxType, stats.dead);

        string memory attributes = observe_cat2(stats.kitDNA, stats.traitBonus);

        string memory uri = string(abi.encodePacked(
                                '{"name": "', name,'", "description": "', description, '", "image": "',
                                baseURI, '"',
                                attributes
                            )
        );

        // for(uint i = 0; i < genome.length;) {

        //     uri = string(abi.encodePacked(uri, ',{"trait_type": "', propertyNames[i], '", "value": ', traitNames[i][genome[i]], '"}'));           


        //     unchecked {
        //         ++i;
        //     }

        // }

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    encode(
                        bytes(string(
                            abi.encodePacked(uri, '}'))
                        )
                    )
                )
            );

    }

    function getDeadCatUri(uint tokenId, uint deathTime, uint raptureTime) external view returns(string memory) {

        string memory name = catNames[tokenId];

        string memory description = catDescriptions[tokenId];

        if(bytes(name).length == 0) {
            name = string(abi.encodePacked(baseName, tokenId.toString()));
        }

        if(bytes(description).length == 0) {
            description = baseDeadDescription;
        }

        string memory baseURI;

        if(getIsIpfs(tokenId)) {

            baseURI = ipfsURI;

        } else {

            baseURI = string(abi.encodePacked(deadURI, tokenId.toString()));

        }

        name = string(abi.encodePacked("The Late ", name));

        string memory attributes = ', "attributes": [{"trait_type": "Living?", "value": "No"}';

        if(raptureTime > 0) {

            if(deathTime > raptureTime) {
                raptureTime = deathTime;
            }

            (uint decayedPercent, uint OccultBonus) = deadCat.getChances(raptureTime);               

            attributes = string(abi.encodePacked(attributes, ',{"display_type": "boost_percentage", "trait_type": "Percent Decayed", "value": ', decayedPercent.toString(), '},{"display_type": "boost_number", "trait_type": "Occult Bonus", "value": ', OccultBonus.toString(), ', "max_value": 100 }'));

        }

        return
        string(
            abi.encodePacked(
                'data:application/json;base64,',
                encode(
                    abi.encodePacked(
                        '{"name": "', name,'", "description": "', description, '", "image": "',
                        baseURI, '"',
                        attributes,
                        ']}'
                    )
                )
            )
        );

        

    }

    function initialize_attributes(uint _attributeIndex, uint8[][] calldata traits, uint8[][] calldata rarities, uint[] calldata thresholds) external onlyOwner {

       require(attributePool[_attributeIndex].length == 0, "Attributes already set");

       require(traits.length == thresholds.length, "Arrays are not the same size");

       require(traits.length == rarities.length, "Arrays are not the same size");

        uint count = traits.length;

        for(uint i = 0; i < count;) {

            attributePool[_attributeIndex].push(traitPool(traits[i], rarities[i], thresholds[i]));

            unchecked {
                ++i;
            }

        }

    }

    function initializeTraitNames(string[] calldata _traitNames, string calldata _propertyName, uint _propertyIndex) external onlyOwner {

        propertyNames[_propertyIndex] = _propertyName;

        for(uint i = 0; i < _traitNames.length;) {

            unchecked {
                
                traitNames[_propertyIndex][i + 1] = _traitNames[i];

                ++i;
            }

        }

    }

    function decode_kitDNA(uint _index, uint dna, uint rawr_modifier) internal view returns(uint) {
       
        dna = dna / (100 ** (_index));

        uint trait_pool_determiner = (dna % 100)+rawr_modifier;

        traitPool[] memory pools = attributePool[_index]; 

        for(uint i=0; i < pools.length;){
            if (trait_pool_determiner < pools[i].thresh) {

                // PICK RANDOM TRAIT
                uint8 determiner = uint8(uint(keccak256(abi.encodePacked(dna))) % 200);

                for(uint j = 0; i < pools[i].rarities.length;) {

                    if (determiner < pools[i].rarities[j]) {

                        return pools[i].possibleTraits[j];

                    }

                    unchecked {
                        ++j;
                    }
                }

            }

            unchecked {
                ++i;
            }
        }

        return 0;
    }

    function decode_kitDNA2(uint _index, uint dna, uint rawr_modifier) internal view returns(string memory) {
       
        dna = dna / (100 ** (_index));

        uint trait_pool_determiner = (dna % 100) + rawr_modifier;

        traitPool[] memory pools = attributePool[_index]; 

        for(uint i=0; i < pools.length;){
            if (trait_pool_determiner < pools[i].thresh) {

                // PICK RANDOM TRAIT
                uint8 determiner = uint8(uint(keccak256(abi.encodePacked(dna))) % 200);

                for(uint j = 0; i < pools[i].rarities.length;) {

                    if (determiner < pools[i].rarities[j]) {

                        return traitNames[_index][pools[i].possibleTraits[j]];

                    }

                    unchecked {
                        ++j;
                    }
                }

            }

            unchecked {
                ++i;
            }
        }

        return "";
    }

    // function observe_cat(uint128 dna, uint8 traitBonus, uint8 boxType, bool dead) public view returns(uint[] memory genotype) {

    //     if (boxType>0){
    //         // CAT STILL IN BOX 
    //         // DISPLAY BOX GRAPHIC
    //         genotype[0] = boxType;
    //         return genotype;
    //     }
        
    //     // CAT OUTA THE BOX LET'S TAKE A PEEKY
        
       
    //     uint rawr_modifier = traitBonus;
        
    //     // genotype[1] = dead ? 1:0;

    //     for(uint i=0; i<numAttributes;){
    //         genotype[i + 2]= decode_kitDNA(i, dna, rawr_modifier);
    //         genotype[i]= decode_kitDNA(i, dna, rawr_modifier);

    //         unchecked {
    //             ++i;
    //         }
    //     }

    //     return genotype; 
    // }

    function observe_cat2(uint128 dna, uint8 traitBonus) public view returns(string memory attributes) {
        
       
        uint rawr_modifier = traitBonus;

        attributes = ', "attributes": [{"trait_type": "Living?", "value": "Yes"}';
    

        for(uint i=0; i<numAttributes;){
            attributes = string(abi.encodePacked(attributes, ', {"trait_type": "', propertyNames[i], '", "value": "', decode_kitDNA2(i, dna, rawr_modifier), '"}'));

            unchecked {
                ++i;
            }
        }

        attributes = string(abi.encodePacked(attributes,']'));

        return attributes; 
    }

    function getIsIpfs(uint tokenId) public view returns(bool) {

        uint index = (tokenId) / 256;

        uint mask = 2 ** (tokenId % 256);

        return (isIpfs[index] & mask) > 0;

    }

   /**
    * @dev Changes the name of your cat
    * @param _name is the desired name to change to
    * @param _tokenId is the id of the token whos description will be changed
    */
    function changeName(string memory _name, uint _tokenId) external payable {

        require(msg.value == textChangeCost, "Invalid value");

        require(canChangeText, "Can't change at this time");

        require(_msgSender() == schrodethersCats.ownerOf(_tokenId), "Only the owner of this token can change the name");

        require(validateText(_name, true) == true, "Invalid name");

        require(nameTaken[_name] == false, "Name is already taken");

        string memory currentName = catNames[_tokenId];

        if(bytes(currentName).length > 0) {

            nameTaken[currentName] = false;

        }

        nameTaken[_name] = true;

        catNames[_tokenId] = _name;


        emit TextChanged(_tokenId);

    }

    /**
    * @dev Changes the description of your cat
    * @param _description is the desired description to change to
    * @param _tokenId is the id of the token whos description will be changed
    */
    function changeDescription(string memory _description, uint _tokenId) external payable {

        require(msg.value == textChangeCost, "Invalid value");

        require(canChangeText, "Can't change at this time");

        require(_msgSender() == schrodethersCats.ownerOf(_tokenId), "Only the owner of this token can change the name");

        require(validateText(_description, false) == true, "Invalid description");

        catDescriptions[_tokenId] = _description;

        emit TextChanged(_tokenId);

    }

    /**
    * @dev Makes sure the name is valid with the constraints set
    * @param _text is the desired text to be verified
    * @param _isName determines if its a name or text field to verify
    * @notice credits to cyberkongz
    */ 
    function validateText(string memory _text, bool _isName) public pure returns (bool){

        bytes memory byteString = bytes(_text);
        
        if(byteString.length == 0) return false;

        if(_isName && byteString.length >= 20) return false;

        else if(byteString.length >= 150) return false;
        
        for(uint i; i < byteString.length; i++){

            bytes1 character = byteString[i];

            //limit the name to only have numbers, letters, or spaces
            if(
                !(character >= 0x30 && character <= 0x39) &&
                !(character >= 0x41 && character <= 0x5A) &&
                !(character >= 0x61 && character <= 0x7A) &&
                !(character == 0x20)
            )
                return false;
        }

        return true;
    }

    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /// @notice developed by Brecht Devos - <brecht@loopring.org>
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }

    function updateIpfs(uint[] calldata _isIpfs, string calldata _uri) external onlyOwner {

        isIpfs = _isIpfs;

        ipfsURI = _uri;

    }

    function withdraw() external onlyOwner {

        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");

    }

    function revertText(uint tokenId, bool isName) external onlyOwner {

        if(isName) {

            delete catNames[tokenId];

        } else {
            delete catDescriptions[tokenId];
        }

    }

    function setCanChangeText(bool _value) external onlyOwner {

        canChangeText = _value;

    }

    // Set parameters used by airnodeRrp.makeFullRequest(...)
    // See makeRequestUint256()
    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address _sponsorWallet
    ) external onlyOwner {
        // Normally, this function should be protected, as in:
        // require(msg.sender == owner, "Sender not owner");
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    function makeUniqueCat(uint tokenId, uint randomness) external {

        uint length = remainingUniqueCats.length;

        if(length == 0) {
            return;
        }

        require(msg.sender == address(schrodethersCats), "You do not decide which cats are special");

        uint index = randomness % length;

        uniqueCats[tokenId] = remainingUniqueCats[index];

        remainingUniqueCats[index] = remainingUniqueCats[length - 1];

        remainingUniqueCats.pop();

    }

    function addUniqueCat(UniqueCat calldata specialCat) external onlyOwner {

        remainingUniqueCats.push(specialCat);

    }

    function getTraitPool(uint propertyIndex, uint poolIndex) external view returns(traitPool memory) {
        return attributePool[propertyIndex][poolIndex];
    }

}