// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "./sbt-achievements.sol";

contract SBT {
    modifier soulExists(uint _soul_id) {
        require(addressOfSoul[_soul_id] != address(0), "No soul exists");
        _;
    }

    modifier soulDoesntExist(uint _soul_id) {
        require(addressOfSoul[_soul_id] == address(0), "Already has a soul");
        _;
    }

    struct PersonalDataHashed {
        bytes32 url_hash;
        bytes32 github_url_hash;
        bytes32 email_address_hash;
    }

    struct PersonalData {
        string url;
        string github_url;
        string email_address;
    }

    struct Soul {
        // uint soul_id;
        PersonalDataHashed hashedData;
    }

    address public operator;
    event Mint(address _soul);
    event Burn(uint _soul_id_to_burn);
    event Update(uint _soul_id_to_update);

    constructor() {
        operator = msg.sender;
    }

    mapping(uint => address) addressOfSoul; //soul_id => address of owner
    mapping(address => uint) soulIdOfAddress; //address => soul_id
    mapping(uint => Soul) souls;

    // Function that hashes content of user's hashedData. Must be rewritten if PersonalData fields change.
    function hashPersonalData(PersonalData memory _data) internal pure returns(PersonalDataHashed memory) {
        PersonalDataHashed memory hashedData;
        hashedData.email_address_hash = keccak256(abi.encodePacked(_data.email_address));
        hashedData.github_url_hash = keccak256(abi.encodePacked(_data.github_url));
        hashedData.url_hash = keccak256(abi.encodePacked(_data.url));
        return hashedData;
    }

    // Mints the SBT for given address and with given soul_id. Can be called only by this contract.
    function mint(
        address _soul_address,
        uint _soul_id,
        PersonalData memory _soulData
    ) external soulDoesntExist(_soul_id) {
        require(msg.sender == operator, "Only operator can mint new souls");
        addressOfSoul[_soul_id] = _soul_address;
        soulIdOfAddress[_soul_address] = _soul_id;
        // souls[_soul_id].soul_id = _soul_id;
        souls[_soul_id].hashedData = hashPersonalData(_soulData);
        emit Mint(_soul_address);
    }

    // Deletes SBT of msg.sender from storage.
    function burn(uint _soul_id_to_burn) external {
        delete souls[_soul_id_to_burn];
        delete soulIdOfAddress[addressOfSoul[_soul_id_to_burn]];
        delete addressOfSoul[_soul_id_to_burn];
        emit Burn(_soul_id_to_burn);
    }

    // Updates hashedData of msg.sender's SBT by replacing with '_newSoulData'.
    function update(PersonalDataHashed memory _newSoulData)
        external
        soulExists(soulIdOfAddress[msg.sender])
    {
        souls[soulIdOfAddress[msg.sender]].hashedData = _newSoulData;
        emit Update(soulIdOfAddress[msg.sender]);
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
    function verifyDataCorrectness(PersonalData memory _dataToVerify) external view returns (bool) {
        PersonalDataHashed memory hashedDataFromStorage = souls[soulIdOfAddress[msg.sender]].hashedData;
        PersonalDataHashed memory hashedDataToVerify = hashPersonalData(_dataToVerify);
        if (hashedDataToVerify.email_address_hash != hashedDataFromStorage.email_address_hash) {
            return false;
        }
        if (hashedDataToVerify.github_url_hash != hashedDataFromStorage.github_url_hash) {
            return false;
        }
        if (hashedDataToVerify.url_hash != hashedDataFromStorage.url_hash) {
            return false;
        }
        return true;
    } 
}
