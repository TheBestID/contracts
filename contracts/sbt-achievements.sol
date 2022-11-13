// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface SBT_interface {
    function getUserId(address _soul) external view returns (uint);
    function getUserAddress(uint _soul_id) external view returns (address);
}

contract SBT_achievement {
    struct Achievement {
        uint achievement_id;
        uint achievement_type;

        uint issuer;
        uint owner;
        bool is_accepted;

        uint verifier;
        bool is_verified;

        string data_address;
        uint balance;
    }

    // [321, 0, 123, 0, false, 0, false, "0"]
    mapping(uint => Achievement) private achievements;
    mapping(uint => uint[]) private issuersAchievements;
    mapping(uint => uint[]) private usersAchievements;

    address public operator;

    address public kSBTContract;
    SBT_interface SBT;
    bool SBTContractIsSet;

    event Mint(uint achievement_id);
    event Burn(uint achievement_id);
    event Update(uint achievement_id);
    event Accept(uint achievement_id);
    event Verify(uint achievement_id, uint balance_send);

    constructor() {
        operator = msg.sender;
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
    }


    function mint(Achievement memory _achievementData) external {
        require(achievements[_achievementData.achievement_id].issuer != 0, "Achievement id already exists");
        require(SBT.getUserId(msg.sender) == _achievementData.issuer, "Only you can be an issuer");
        achievements[_achievementData.achievement_id] = _achievementData;
        issuersAchievements[_achievementData.issuer].push(_achievementData.achievement_id);
        usersAchievements[_achievementData.owner].push(_achievementData.achievement_id);
        
        emit Mint(_achievementData.achievement_id);
    }

    function burn(uint _achievementId) external {
        require(SBT.getUserId(msg.sender) == achievements[_achievementId].issuer, "Only issuer can delete an achievement");
        for (uint i = 0; i < issuersAchievements[achievements[_achievementId].issuer].length; i++) {
            if (_achievementId == issuersAchievements[achievements[_achievementId].issuer][i]) {
                delete issuersAchievements[achievements[_achievementId].issuer][i];
                break;
            }
        }
        for (uint i = 0; i < usersAchievements[achievements[_achievementId].owner].length; i++) {
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
        require(achievements[_achievementId].owner == 0, "Owner of this achievement can not be changed");
        achievements[_achievementId].owner = SBT.getUserId(_newOwner);
        
        emit Update(_achievementId);
    }

    function acceptAchievement(uint _achievementId) external {
        require(SBT.getUserId(msg.sender) == achievements[_achievementId].owner, "Only owner can accept this achievement");
        achievements[_achievementId].is_accepted = true;

        emit Accept(_achievementId);
    }

    function verifyAchievement(uint _achievementId) external {
        require(SBT.getUserId(msg.sender) == achievements[_achievementId].verifier, "Only verifier can verify an achievement");
        require(achievements[_achievementId].is_verified == false, "Achievement already verified");

        uint balance = achievements[_achievementId].balance;
        achievements[_achievementId].balance = 0;
        address payable owner = payable(SBT.getUserAddress(achievements[_achievementId].owner));
        owner.transfer(balance);

        achievements[_achievementId].is_verified = true;

        emit Verify(_achievementId, balance);
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

    function replenishAchievementBalance(uint _achievementId) external payable {
        achievements[_achievementId].balance += msg.value;
    }
}
