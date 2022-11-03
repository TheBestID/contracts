// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./sbt-achievements.sol";

contract SBT {
    modifier soulExists(uint _soul_id) {
        require(addressOfSoul[_soul_id] == address(0), "Already has a soul");
        _;
    }

    modifier soulDoesntExist(uint _soul_id) {
        require(addressOfSoul[_soul_id] != address(0), "Already has a soul");
        _;
    }

    struct PersonalData {
        string url;
        string github_url;
        string email_address;
    }

    struct Soul {
        uint soul_id;
        PersonalData data;
    }

    address public operator;
    event Mint(address _soul);
    event Burn(uint _soul_id_to_burn);
    event Update(uint _soul_id_to_update);

    constructor() {
        operator = msg.sender;
    }

    mapping(uint => address) addressOfSoul; //soul_id => address of owner
    mapping(address => uint) soulOfAddress; //address => soul_id
    mapping(uint => Soul) souls;

    // Mints the SBT for given address and with given soul_id. Can be called only by this contract.
    function mint(
        address _soul_address,
        uint _soul_id,
        PersonalData memory _soulData
    ) external soulDoesntExist(_soul_id) {
        require(msg.sender == operator, "Only operator can mint new souls");
        addressOfSoul[_soul_id] = _soul_address;
        soulOfAddress[_soul_address] = _soul_id;
        souls[_soul_id].soul_id = _soul_id;
        souls[_soul_id].data = _soulData;
        emit Mint(_soul_address);
    }

    // Deletes SBT of msg.sender from storage.
    function burn(uint _soul_id_to_burn) external {
        delete souls[_soul_id_to_burn];
        delete soulOfAddress[addressOfSoul[_soul_id_to_burn]];
        delete addressOfSoul[_soul_id_to_burn];
        emit Burn(_soul_id_to_burn);
    }

    // Updates data of msg.sender's SBT by replacing with '_newSoulData'.
    function update(PersonalData memory _newSoulData)
        external
        soulExists(soulOfAddress[msg.sender])
    {
        souls[soulOfAddress[msg.sender]].data = _newSoulData;
        emit Update(soulOfAddress[msg.sender]);
    }

    // Returns true, if there is an SBT for given address.
    function hasSoul(address _soul) external view returns (bool) {
        return soulOfAddress[_soul] != 0;
    }

    // Returns SBT of given address, if there is one; otherwise throws an error.
    function getSoul(address _soul) external view returns (Soul memory) {
        require(soulOfAddress[_soul] != 0, "Soul doesn't exist");
        return souls[soulOfAddress[_soul]];
    }

    // Returns owner of given '_soul_id', if there is one; otherwise returns NULL-address.
    function getOwner(uint _soul_id) external view returns (address) {
        require(
            msg.sender == operator,
            "Only this contract can view this data"
        );
        return addressOfSoul[_soul_id];
    }
}
