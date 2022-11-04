//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

struct catStats {

    uint128 kitDNA;
    uint8 traitBonus;
    uint32 timePacked;
    uint32 timeUnpacked;
    uint8 boxType;
    uint48 leftover;

    uint256 extraSpace;

}