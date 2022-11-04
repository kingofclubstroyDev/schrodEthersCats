//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./structs/MetadataStruct.sol";
import "hardhat/console.sol";

contract MetadataManager is Ownable {

    using Strings for uint;

    event TextChanged(uint indexed tokenId);
    event SpecialCatCreated(uint indexed tokenId);

    mapping(uint => address) collectionAddress;

    struct traitPool {
        uint8[] possibleTraits;
        uint8[] rarities;
        uint thresh;
    }

    mapping(uint => mapping(uint => traitPool[])) public attributePool;

    mapping(uint => mapping(uint => string)) public propertyNames;

    mapping(uint => mapping(uint => mapping(uint => string))) public traitNames;

    uint[] isIpfs;
    string public ipfsURI;

    //TODO: change this to 0.02 ether
    uint constant textChangeCost = 0.000001 ether;
    bool public canChangeText = false;

    mapping(uint => string) public catNames;
    mapping(string => bool) nameTaken;
    mapping(uint => string) public catDescriptions;

    struct UniqueCat {
        string ipfs;
        string attributes;
        string name;
        string description;
    }

    mapping(uint => UniqueCat[]) remainingUniqueCats;

    mapping(uint => UniqueCat) uniqueCats;

    uint constant percision = 100;


    function getTokenUri(uint tokenId, MetadataStruct memory metadata, uint collectionId) external view returns(string memory) {

        string memory name;
        string memory description;
        string memory imageURI;
        string memory attributes;

        if(bytes(uniqueCats[tokenId].ipfs).length > 0) {

            UniqueCat memory specialCat = uniqueCats[tokenId];
            name = specialCat.name;
            description = specialCat.description;
            attributes = specialCat.attributes;
            imageURI = specialCat.ipfs;

        } 
        else {

            name = catNames[tokenId];

            if(bytes(name).length == 0) {
                name = string(abi.encodePacked(metadata.baseName, tokenId.toString()));
            }

            name = string(abi.encodePacked(metadata.preName, name));

            description = catDescriptions[tokenId];

            if(bytes(description).length == 0) {
                description = metadata.baseDescription;
            }

            imageURI = metadata.imageURI;

            // if(getIsIpfs(tokenId)) {

            //     imageURI = ipfsURI;
            // }

            if(metadata.hasTraits) {
                // if(bytes(metadata.attributes).length > 0) {
                //     //there are attributes passed in, so add a comma
                //     attributes = ",";
                // }
                attributes = string(abi.encodePacked(attributes, observe_cat(metadata.kitDNA, metadata.traitBonus, metadata.numberAttributes, collectionId)));
            }
        }

        return   string(
                        abi.encodePacked(
                            '{"name": "',
                            name,
                            '", "description": "',
                            description,
                            '", "image": "',
                            imageURI,
                            '", "attributes":[',
                            metadata.attributes,
                            attributes,
                            ']}'
                        )
                    );
        //string(
                    //abi.encodePacked(
                        //'data:application/json;base64,',
                        //encode(
                            //bytes(
                                // string(
                                //     abi.encodePacked(
                                //         '{"name": "',
                                //         name,
                                //         '", "description": "',
                                //         description,
                                //         '", "image": "',
                                //         imageURI,
                                //         '", "attributes":[',
                                //         metadata.attributes,
                                //         attributes,
                                //         ']}'
                                //     )
                                // )
                            //)
                        //)
                    //)
                //);

    }

    function decode_kitDNA(uint _index, uint dna, uint rawr_modifier, uint collectionId) internal view returns(string memory) {
       
        dna = dna / (100 ** (_index));

        uint trait_pool_determiner = (dna % 100) + rawr_modifier;

        traitPool[] memory pools = attributePool[collectionId][_index];

        for(uint i=0; i < pools.length;){

            if (trait_pool_determiner < pools[i].thresh) {

                if(i == 3) {
                    console.log("pool 4!!!");
                    console.log("trait_pool determiner = ", trait_pool_determiner);
                    console.log("pool threshold = ", pools[i].thresh);
                    console.log("pools length = ", pools.length);
                    console.log("pools previous threshold = ", pools[i - 1].thresh);

                }

                // PICK RANDOM TRAIT
                uint determiner = uint(keccak256(abi.encodePacked(dna))) % percision;

                uint cumulativeRarity;

                for(uint j = 0; j < pools[i].rarities.length;) {

                    cumulativeRarity += pools[i].rarities[j];

                    if (determiner <= cumulativeRarity) {

                        return traitNames[collectionId][_index][pools[i].possibleTraits[j]];

                    }

                    unchecked {
                        ++j;
                    }
                }

                console.log("failure to find trait in pool");
                console.log("trait determiner = ", determiner);
                console.log("cumulative rarity = ", cumulativeRarity);
                console.log("attribute index = ", _index);
                console.log("pool index = ", i + 1);
                console.log("proterty name = ", propertyNames[collectionId][_index]);

               

                revert("did not find trait");

            }

            unchecked {
                ++i;
            }
        }

        return "";
    }

    function observe_cat(uint128 dna, uint8 traitBonus, uint numAttributes, uint collectionId) public view returns(string memory attributes) {
        
        uint rawr_modifier = traitBonus;

        for(uint i = 0; i < numAttributes;){

            string memory trait = decode_kitDNA(i, dna, rawr_modifier, collectionId);

            if(bytes(trait).length == 0) {
                trait = "None";
            }

            attributes = string(abi.encodePacked(attributes, ', {"trait_type": "', propertyNames[collectionId][i], '", "value": "', trait, '"}'));

            unchecked {
                ++i;
            }
        }

        return attributes; 
    }

    function getIsIpfs(uint tokenId) public view returns(bool) {

        uint index = (tokenId) / 256;

        uint mask = 2 ** (tokenId % 256);

        return (isIpfs[index] & mask) > 0;

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

    /**
    * @dev Changes the name of your cat
    * @param _name is the desired name to change to
    * @param _tokenId is the id of the token whos description will be changed
    */
    function changeName(string memory _name, uint _tokenId, uint collectionId) external payable {

        require(msg.value == textChangeCost, "Invalid value");

        require(canChangeText, "Can't change at this time");

        require(msg.sender == IERC721(collectionAddress[collectionId]).ownerOf(_tokenId), "Only the owner of this token can change the name");

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
    function changeDescription(string memory _description, uint _tokenId, uint collectionId) external payable {

        require(msg.value == textChangeCost, "Invalid value");

        require(canChangeText, "Can't change at this time");

        require(msg.sender == IERC721(collectionAddress[collectionId]).ownerOf(_tokenId), "Only the owner of this token can change the description");

        require(validateText(_description, false) == true, "Invalid description");

        catDescriptions[_tokenId] = _description;

        emit TextChanged(_tokenId);

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

    function makeUniqueCat(uint tokenId, uint randomness, uint collectionId) external {

        uint length = remainingUniqueCats[collectionId].length;

        require(collectionAddress[collectionId] == msg.sender, "You do not decide which cats are special");

        if(length == 0) {
            return;
        }


        uint index = randomness % length;

        uniqueCats[tokenId] = remainingUniqueCats[collectionId][index];

        remainingUniqueCats[collectionId][index] = remainingUniqueCats[collectionId][length - 1];

        remainingUniqueCats[collectionId].pop();

        emit SpecialCatCreated(tokenId);

    }

    function addUniqueCat(UniqueCat calldata specialCat, uint collectionId) external onlyOwner {

        remainingUniqueCats[collectionId].push(specialCat);

    }

    function initialize_attributes(uint _attributeIndex, uint8[][] calldata traits, uint8[][] calldata rarities, uint[] calldata thresholds, uint collectionId) external onlyOwner {

       require(attributePool[collectionId][_attributeIndex].length == 0, "Attributes already set");

       require(traits.length == thresholds.length, "Arrays are not the same size");

       require(traits.length == rarities.length, "Arrays are not the same size");

        uint count = traits.length;

        for(uint i = 0; i < count;) {

            attributePool[collectionId][_attributeIndex].push(traitPool(traits[i], rarities[i], thresholds[i]));

            unchecked {
                ++i;
            }

        }

    }

    function initializeTraitNames(string[] calldata _traitNames, uint[] calldata _traitNums, string calldata _propertyName, uint _propertyIndex, uint collectionId) external onlyOwner {

        propertyNames[collectionId][_propertyIndex] = _propertyName;

        for(uint i = 0; i < _traitNames.length;) {

            unchecked {
                
                traitNames[collectionId][_propertyIndex][_traitNums[i]] = _traitNames[i];

                ++i;
            }

        }

    }

    function addCollection(address _collectionAddress, uint _collectionId) external onlyOwner {

        collectionAddress[_collectionId] = _collectionAddress;

    }

    function updateIpfs(uint[] calldata _isIpfs, string calldata _uri) external onlyOwner {

        isIpfs = _isIpfs;

        ipfsURI = _uri;

    }

}