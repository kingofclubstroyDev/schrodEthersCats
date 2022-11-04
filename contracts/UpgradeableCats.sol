//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "./VRFConsumerBase.sol";
// import "./VRFConsumerBaseV2.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
// import "./Libraries/PRBMathSD59x18.sol";

// //import "hardhat/console.sol";

// //contract SchrodEthersCat is Initializable, OwnableUpgradeable, PaymentSplitterUpgradeable,  ERC721Upgradeable, VRFConsumerBase, VRFConsumerBaseV2, UUPSUpgradeable {
// contract SchrodEthersCat is Initializable, OwnableUpgradeable, PaymentSplitterUpgradeable,  ERC721Upgradeable, UUPSUpgradeable {
contract UpgradeableCats is UUPSUpgradeable {

    function initialize() public initializer {

        // __Ownable_init();
        // __ERC721_init("SchrodEthersCat", "SEC");
        // __PaymentSplitter_init(payees, shares_);

        //_safeMint(msg.sender, 1);
        
    }


    function _authorizeUpgrade(address) internal view override {}





}
