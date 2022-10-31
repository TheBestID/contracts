// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./sbt-achievements.sol";

contract SBT {
    modifier soulExists(uint _addr) {
        require(_addr != 0, "Soul doesn't exist");
        _;
    }

    modifier soulDoesntExist(uint _addr) {
        require(_addr == 0, "Soul exists");
        _;
    }

    struct PersonalData {
        string url;
        string github_url;
        string email_address;
    }

    struct Soul {
        uint soul_id;
        // PersonalData data;
        string url;
    }
    // TODO: later
    // mapping (uint => SBT_achievement[]) private soulAchievements; // uint = soul_id of Soul
    mapping(address => Soul) private souls;
    mapping(uint => address) private ownerOfSoul;

    address public operator;

    event Mint(address _soul);
    event Burn(address _soul);
    event Update(address _soul);
    event SetProfile(address _profiler, address _soul);
    event RemoveProfile(address _profiler, address _soul);

    constructor() {
        operator = msg.sender;
    }

    function mint(
        address _soul,
        uint _soul_id,
        string memory _soulData
        // PersonalData memory _soulData
    ) external soulDoesntExist(souls[_soul].soul_id) {
        require(msg.sender == operator, "Only operator can mint new souls");
        // souls[_soul].data = _soulData;
        souls[_soul].url = _soulData;
        souls[_soul].soul_id = _soul_id;
        ownerOfSoul[_soul_id] = _soul;
        emit Mint(_soul);
    }

    function burn(address _soul) external {
        require(
            msg.sender == _soul,
            "Only users have rights to delete their data"
        );
        delete ownerOfSoul[souls[_soul].soul_id];
        delete souls[_soul];
        emit Burn(_soul);
    }

    function update(address _soul, PersonalData memory _soulData)
        external
        soulExists(souls[_soul].soul_id)
    {
        require(
            ownerOfSoul[souls[_soul].soul_id] == msg.sender,
            "Only owner can update their soul data"
        );
        souls[_soul].url = _soulData.url;
        // souls[_soul].data = _soulData;
        emit Update(_soul);
    }

    function hasSoul(address _soul) external view returns (bool) {
        return souls[_soul].soul_id != 0;
    }

    function getSoul(address _soul) external view returns (Soul memory) {
        return souls[_soul];
    }

    function getOwner(uint _soul_id) external view returns (address) {
        return ownerOfSoul[_soul_id];
    }
}
