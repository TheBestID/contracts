// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract SBT_achievement {
    struct Achievement {
        uint achievement_id;
        uint achievement_type;

        address issuer;
        bool can_owner_be_changed;
        address owner;

        address verifier;
        bool is_verified;

        bytes32 data_hash;
    }

    mapping (uint => Achievement) private achievements;
    mapping (address => uint[]) private issuersAchievements;
    mapping (address => uint[]) private usersAchievements;

    address public operator;

    event Mint(uint achievement_id);
    event Burn(uint achievement_id);
    event Update(uint achievement_id);
    event Verify(uint achievement_id);

    constructor() {
      operator = msg.sender;
    }

    function mint(Achievement memory _achievementData) external {
        require(msg.sender == _achievementData.issuer, "Only you can be an issuer");
        issuersAchievements[_achievementData.issuer].push(_achievementData.achievement_id);
        usersAchievements[_achievementData.owner].push(_achievementData.achievement_id);
        emit Mint(_achievementData.achievement_id);
    }

    function burn(uint _achievementId) external {
        require(msg.sender == achievements[_achievementId].issuer, "Only issuer can delete an achievement");
        for (uint i=0; i<issuersAchievements[achievements[_achievementId].issuer].length; i++) {
            if (_achievementId == issuersAchievements[achievements[_achievementId].issuer][i]) {
                delete issuersAchievements[achievements[_achievementId].issuer][i];
                break;
            }
        }
        for (uint i=0; i<usersAchievements[achievements[_achievementId].owner].length; i++) {
            if (_achievementId == usersAchievements[achievements[_achievementId].owner][i]) {
                delete usersAchievements[achievements[_achievementId].owner][i];
                break;
            }
        }
        delete achievements[_achievementId];
        emit Burn(_achievementId);
    }

    function updateOwner(uint _achievementId, address _newOwner) external {
        require(msg.sender == achievements[_achievementId].issuer, "Only issuer can change an owner");
        require(achievements[_achievementId].can_owner_be_changed, "Owner of this achievement can not be changed");
        achievements[_achievementId].owner = _newOwner;
        achievements[_achievementId].can_owner_be_changed = false;
        emit Update(_achievementId);
    }

    function changeAchievementVerification(uint _achievementId, bool _newStatus) external {
        require(msg.sender == achievements[_achievementId].verifier, "Only verifier can verify or unverify an achievement");
        achievements[_achievementId].is_verified = _newStatus;
        emit Verify(_achievementId);
    }
}
