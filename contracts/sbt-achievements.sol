// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface SBT_interface {
    function getUserId(address _soul) external view returns (uint);
}

contract SBT_achievement {
    struct Achievement {
        uint achievement_id;
        uint achievement_type;

        uint issuer;
        bool can_owner_be_changed;
        uint owner;
        bool is_achievement_accepted;

        uint verifier;
        bool is_verified;

        string data_address;
    }

    // [0, 0, 1, false, 0, false, 0, false, "0"]
    mapping (uint => Achievement) private achievements;
    mapping (uint => uint[]) private issuersAchievements;
    mapping (uint => uint[]) private usersAchievements;

    address public operator;
    address public kSBTContract = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    SBT_interface SBT;
    event Mint(uint achievement_id);
    event Burn(uint achievement_id);
    event Update(uint achievement_id);
    event Accept(uint achievement_id);
    event Verify(uint achievement_id);
    bool SBTContractIsSet;

    constructor() {
      operator = msg.sender;
    //   SBT = SBT_interface(kSBTContract);
      SBTContractIsSet = false;
    }

    function setSBTContractAddress(address _new_address) external {
        require(
            msg.sender == operator,
            "Only this contract can set this address"
        );
        require(
            SBTContractIsSet == false,
            "SBT contract address is already set"
        );
        kSBTContract = _new_address;
        SBTContractIsSet = true;
        SBT = SBT_interface(kSBTContract);
        // emit SetAchevementsContractAddress(_new_address);
    }


    function mint(Achievement memory _achievementData) external {
        // FIXME: must be unique achievement_id
        require(SBT.getUserId(msg.sender) == _achievementData.issuer, "Only you can be an issuer");
        achievements[_achievementData.achievement_id] = _achievementData;
        issuersAchievements[_achievementData.issuer].push(_achievementData.achievement_id);
        usersAchievements[_achievementData.owner].push(_achievementData.achievement_id);
        emit Mint(_achievementData.achievement_id);
    }

    function burn(uint _achievementId) external {
        require(SBT.getUserId(msg.sender) == achievements[_achievementId].issuer, "Only issuer can delete an achievement");
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
        require(SBT.getUserId(msg.sender) == achievements[_achievementId].issuer, "Only issuer can change an owner");
        require(achievements[_achievementId].can_owner_be_changed, "Owner of this achievement can not be changed");
        achievements[_achievementId].owner = SBT.getUserId(_newOwner);
        achievements[_achievementId].can_owner_be_changed = false;
        emit Update(_achievementId);
    }

    function acceptAchievement(uint _achievementId) external {
        require(SBT.getUserId(msg.sender) == achievements[_achievementId].owner, "Only owner can accept this achievement");
        achievements[_achievementId].is_achievement_accepted = true;
        emit Accept(_achievementId);
    }

    function changeAchievementVerification(uint _achievementId, bool _newStatus) external {
        require(SBT.getUserId(msg.sender) == achievements[_achievementId].verifier, "Only verifier can verify or unverify an achievement");
        achievements[_achievementId].is_verified = _newStatus;
        emit Verify(_achievementId);
    }

    function getAchievementInfo(uint _achievementId) external view returns (Achievement memory) {
        require(msg.sender == operator || 
                SBT.getUserId(msg.sender) == achievements[_achievementId].issuer ||
                SBT.getUserId(msg.sender) == achievements[_achievementId].owner ||
                SBT.getUserId(msg.sender) == achievements[_achievementId].verifier, 
                "Only operator, issuer, owner or verifier can get achievement info");
        return achievements[_achievementId];
    }

    function getAchievementsOfIssuer(address _issuer) external view returns (uint[] memory) {
        require(msg.sender == operator || msg.sender == _issuer, "Only operator or issuer can get this info");
        return issuersAchievements[SBT.getUserId(_issuer)];
    }

    function getAchievementsOfOwner(address _owner) external view returns (uint[] memory) {
        require(msg.sender == operator || msg.sender == _owner, "Only operator or owner can get this info");
        return usersAchievements[SBT.getUserId(_owner)];
    }
}
