// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface SBT_achievement_interface {
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

    function mint(Achievement memory _achievementData) external;

    function burn(uint _achievementId) external;

    function updateOwner(uint _achievementId, address _newOwner) external;

    function changeAchievementVerification(uint _achievementId, bool _newStatus)
        external;
}

contract SBT {
    modifier soulExists(uint _soul_id) {
        require(addressOfSoul[_soul_id] != address(0), "Soul doesn't exist");
        _;
    }

    modifier mintedNotClaimedModifier(uint _soul_id) {
        require(
            addressOfSoul[_soul_id] == address(0),
            "Soul is already claimed"
        );
        require(mintedNotClaimed[_soul_id], "Non minted soul");
        _;
    }

    modifier notMinted(uint _soul_id) {
        require(addressOfSoul[_soul_id] == address(0), "Soul exists");
        require(!mintedNotClaimed[_soul_id], "Soul is minted, but not claimed");
        _;
    }

    struct PersonalDataHashed {
        bytes32 github_hash;
        bytes32 email_address_hash;
    }

    struct PersonalData {
        string github_url;
        string email_address;
    }

    struct Soul {
        uint soul_id;
        PersonalDataHashed hashedData;
    }

    address public operator;
    address public kAchevementsContract =
        0x8016619281F888d011c84d2E2a5348d9417c775B;

    SBT_achievement_interface SBT_achievement;
    event Mint(uint _soul_id);
    event Claim(uint _soul_id);
    event MintAchievement(uint _soul_id);
    event Burn(uint _soul_id_to_burn);
    event Update(uint _soul_id_to_update);
    event SetAchevementsContractAddress(address _new_address);

    constructor() {
        SBT_achievement = SBT_achievement_interface(kAchevementsContract);
        operator = msg.sender;
    }

    mapping(uint => address) private addressOfSoul; //soul_id => address of owner
    mapping(address => uint) soulIdOfAddress; //address => soul_id
    mapping(uint => Soul) private souls;
    mapping(uint => bool) private mintedNotClaimed;

    // Function that hashes content of user's hashedData. Must be rewritten if PersonalData fields change.
    function hashPersonalData(PersonalData memory _data)
        internal
        pure
        returns (PersonalDataHashed memory)
    {
        PersonalDataHashed memory hashedData;
        hashedData.email_address_hash = keccak256(
            abi.encodePacked(_data.email_address)
        );
        hashedData.github_hash = keccak256(abi.encodePacked(_data.github_url));
        return hashedData;
    }

    function setAchevementsContractAddress(address _new_address) external {
        require(
            msg.sender == operator,
            "Only this contract can set this address"
        );
        kAchevementsContract = _new_address;
        emit SetAchevementsContractAddress(_new_address);
    }

    // Mints the SBT for given address and with given soul_id. Can be called only by this contract.
    function mint(address _soul_address, uint _soul_id)
        external
        notMinted(_soul_id)
    {
        require(msg.sender == operator, "Only operator can mint new souls");
        soulIdOfAddress[_soul_address] = _soul_id;
        mintedNotClaimed[_soul_id] = true;
        emit Mint(_soul_id);
    }

    // After minting and SBT, user must claim ownership of SBT by
    function claim(PersonalDataHashed memory _soulData)
        external
        mintedNotClaimedModifier(soulIdOfAddress[msg.sender])
    {
        uint _soul_id = soulIdOfAddress[msg.sender];
        delete mintedNotClaimed[_soul_id];
        addressOfSoul[_soul_id] = msg.sender;
        souls[_soul_id].soul_id = _soul_id;
        souls[_soul_id].hashedData = _soulData;
        emit Claim(_soul_id);
    }

    // After minting and SBT, user must claim ownership of SBT by
    function mint_achievement(
        SBT_achievement_interface.Achievement memory _achievementData
    ) external soulExists(soulIdOfAddress[msg.sender]) {
        SBT_achievement.mint(_achievementData);
        emit MintAchievement(soulIdOfAddress[msg.sender]);
    }

    // Deletes SBT of msg.sender from storage.
    function burn() external soulExists(soulIdOfAddress[msg.sender]) {
        uint _soul_id_to_burn = soulIdOfAddress[msg.sender];
        delete souls[_soul_id_to_burn];
        delete soulIdOfAddress[msg.sender];
        delete addressOfSoul[_soul_id_to_burn];
        emit Burn(_soul_id_to_burn);
    }

    // Returns true, if there is an SBT for given address.
    function hasSoul(address _soul) external view returns (bool) {
        return soulIdOfAddress[_soul] != 0;
    }

    // Returns SBT of given address, if there is one; otherwise throws an error.
    function getSoul(address _soul) external view returns (Soul memory) {
        require(soulIdOfAddress[_soul] != 0, "Soul doesn't exist");
        return souls[soulIdOfAddress[_soul]];
    }

    // Returns owner of given '_soul_id', if there is one; otherwise returns NULL-address.
    function getOwner(uint _soul_id) external view returns (address) {
        require(
            msg.sender == operator,
            "Only this contract can view this hashed data"
        );
        return addressOfSoul[_soul_id];
    }

    // Allows user to verify, that their data stored in our app is it's own and doesn't change.
    function verifyDataCorrectness()
        external
        view
        returns (PersonalDataHashed memory)
    {
        return souls[soulIdOfAddress[msg.sender]].hashedData;
    }
}
