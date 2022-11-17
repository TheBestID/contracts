// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {
AccessControlEnumerableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {
IERC1363ReceiverUpgradeable
} from "@openzeppelin/contracts-upgradeable/interfaces/IERC1363ReceiverUpgradeable.sol";

interface PersonalToken_interface is IERC20Upgradeable {
    function mint(address _owner, uint256 _amount) external;

    function burn(address _owner, uint256 _amount) external;

    function talent() external view returns (address);

    function mintingFinishedAt() external view returns (uint256);

    function mintingAvailability() external view returns (uint256);
}

contract PersonalToken is
Initializable,
ContextUpgradeable,
ERC165Upgradeable,
AccessControlUpgradeable,
ERC1363Upgradeable,
UUPSUpgradeable,
PersonalToken_interface
{
    bytes32 public constant ROLE_TALENT = keccak256("TALENT");

    bytes32 public constant ROLE_MINTER = keccak256("MINTER");

    uint256 public constant MAX_SUPPLY = 1000000 ether;

    uint256 public override(PersonalToken_interface) mintingAvailability;

    uint256 public override(PersonalToken_interface) mintingFinishedAt;

    address public override(PersonalToken_interface) talent;

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _talent,
        address _minter,
        address _admin
    ) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC20_init_unchained(_name, _symbol);
        __AccessControl_init_unchained();

        talent = _talent;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ROLE_TALENT, _talent);
        _setupRole(ROLE_MINTER, _minter);

        _setRoleAdmin(ROLE_TALENT, ROLE_TALENT);

        _mint(_talent, _initialSupply);
        mintingAvailability = MAX_SUPPLY - _initialSupply;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    override(UUPSUpgradeable)
    onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function mint(address _to, uint256 _amount) public override(PersonalToken_interface) onlyRole(ROLE_MINTER) {
        require(mintingAvailability >= _amount, "_amount exceeds minting availability");
        mintingAvailability -= _amount;

        if (mintingAvailability == 0) {
            mintingFinishedAt = block.timestamp;
        }

        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public override(PersonalToken_interface) onlyRole(ROLE_MINTER) {
        if (mintingAvailability > 0) {
            mintingAvailability += _amount;
        }

        _burn(_from, _amount);
    }

    function transferTalentWallet(address _newTalent) public {
        talent = _newTalent;
        grantRole(ROLE_TALENT, _newTalent);
        revokeRole(ROLE_TALENT, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165Upgradeable, AccessControlUpgradeable, ERC1363Upgradeable)
    returns (bool)
    {
        return
        interfaceId == type(IERC20Upgradeable).interfaceId ||
        interfaceId == type(IERC1363Upgradeable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

}


interface PersonalFactory_interface {
    function isTalentToken(address addr) external view returns (bool);

    function isSymbol(string memory symbol) external view returns (bool);
}

contract PersonalFactory is
Initializable,
ContextUpgradeable,
ERC165Upgradeable,
AccessControlEnumerableUpgradeable,
PersonalFactory_interface
{
    bytes32 public constant ROLE_MINTER = keccak256("MINTER");

    uint256 public constant INITIAL_SUPPLY = 2000 ether;

    mapping(address => address) public talentsToTokens;

    mapping(address => address) public tokensToTalents;

    mapping(string => address) public symbolsToTokens;

    address public minter;

    address public implementationBeacon;

    event TalentCreated(address indexed talent, address indexed token);

    function initialize() public virtual initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControlEnumerable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        UpgradeableBeacon _beacon = new UpgradeableBeacon(address(new PersonalToken()));
        _beacon.transferOwnership(msg.sender);
        implementationBeacon = address(_beacon);
    }

    function setMinter(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(minter == address(0x0), "minter already set");

        minter = _minter;
        _setupRole(ROLE_MINTER, _minter);
    }

    function createTalent(
        address _talent,
        string memory _name,
        string memory _symbol
    ) public returns (address) {
        require(!isSymbol(_symbol), "talent token with this symbol already exists");
        require(_isMinterSet(), "minter not yet set");

        BeaconProxy proxy = new BeaconProxy(
            implementationBeacon,
            abi.encodeWithSelector(
                PersonalToken(address(0x0)).initialize.selector,
                _name,
                _symbol,
                INITIAL_SUPPLY,
                _talent,
                minter,
                getRoleMember(DEFAULT_ADMIN_ROLE, 0)
            )
        );

        address token = address(proxy);

        symbolsToTokens[_symbol] = token;
        tokensToTalents[token] = _talent;

        emit TalentCreated(_talent, token);

        return token;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165Upgradeable, AccessControlEnumerableUpgradeable)
    returns (bool)
    {
        return AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    function isTalentToken(address addr) public view override(PersonalFactory_interface) returns (bool) {
        return tokensToTalents[addr] != address(0x0);
    }

    function isSymbol(string memory _symbol) public view override(PersonalFactory_interface) returns (bool) {
        return symbolsToTokens[_symbol] != address(0x0);
    }

    function _isMinterSet() private view returns (bool) {
        return minter != address(0x0);
    }
}


interface IRewardParameters {
    function start() external view returns (uint256);

    function end() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function rewardsMax() external view returns (uint256);

    function rewardsGiven() external view returns (uint256);

    function rewardsLeft() external view returns (uint256);

    function totalAdjustedShares() external view returns (uint256);
}

abstract contract RewardCalculator is Initializable, IRewardParameters {
    uint256 internal constant MUL = 1e10;

    function __RewardCalculator_init() public initializer {}

    function calculateReward(
        uint256 _shares,
        uint256 _stakerS,
        uint256 _currentS,
        uint256 _stakerWeight,
        uint256 _talentWeight
    ) internal pure returns (uint256, uint256) {
        uint256 total = (sqrt(_shares) * (_currentS - _stakerS)) / MUL;
        uint256 talentShare = _calculateTalentShare(total, _stakerWeight, _talentWeight);

        return (total - talentShare, talentShare);
    }

    function calculateGlobalReward(uint256 _start, uint256 _end) internal view returns (uint256) {
        (uint256 start, uint256 end) = _truncatePeriod(_start, _end);
        (uint256 startPercent, uint256 endPercent) = _periodToPercents(start, end);

        uint256 percentage = _curvePercentage(startPercent, endPercent);

        return ((percentage * this.rewardsMax()));
    }

    function _calculateTalentShare(
        uint256 _rewards,
        uint256 _stakerWeight,
        uint256 _talentWeight
    ) internal pure returns (uint256) {
        uint256 stakeAdjustedWeight = sqrt(_stakerWeight * MUL);
        uint256 talentAdjustedWeight = sqrt(_talentWeight * MUL);

        uint256 talentWeight = (talentAdjustedWeight * MUL) / ((stakeAdjustedWeight + talentAdjustedWeight));
        uint256 talentRewards = (_rewards * talentWeight) / MUL;
        uint256 minTalentRewards = _rewards / 100;

        if (talentRewards < minTalentRewards) {
            talentRewards = minTalentRewards;
        }

        return talentRewards;
    }

    function _truncatePeriod(uint256 _start, uint256 _end) internal view returns (uint256, uint256) {
        if (_end <= this.start() || _start >= this.end()) {
            return (this.start(), this.start());
        }

        uint256 periodStart = _start < this.start() ? this.start() : _start;
        uint256 periodEnd = _end > this.end() ? this.end() : _end;

        return (periodStart, periodEnd);
    }

    function _periodToPercents(uint256 _start, uint256 _end) internal view returns (uint256, uint256) {
        uint256 totalDuration = this.end() - this.start();

        if (totalDuration == 0) {
            return (0, 1);
        }

        uint256 startPercent = ((_start - this.start()) * MUL) / totalDuration;
        uint256 endPercent = ((_end - this.start()) * MUL) / totalDuration;

        return (startPercent, endPercent);
    }

    function _curvePercentage(uint256 _start, uint256 _end) internal pure returns (uint256) {
        int256 maxArea = _integralAt(MUL) - _integralAt(0);
        int256 actualArea = _integralAt(_end) - _integralAt(_start);

        uint256 ratio = uint256((actualArea * int256(MUL)) / maxArea);

        return ratio;
    }

    function _integralAt(uint256 _x) internal pure returns (int256) {
        int256 x = int256(_x);
        int256 m = int256(MUL);

        return (x ** 3) / 3 - m * x ** 2 + m ** 2 * x;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        else if (x <= 3) return 1;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

contract Staking is
Initializable,
ContextUpgradeable,
ERC165Upgradeable,
AccessControlEnumerableUpgradeable,
RewardCalculator,
IERC1363ReceiverUpgradeable {
    struct StakeData {
        uint256 tokenAmount;
        uint256 talentAmount;
        uint256 lastCheckpointAt;
        uint256 S;
        bool finishedAccumulating;
    }

    enum RewardAction {
        WITHDRAW,
        RESTAKE
    }

    bytes4 constant ERC1363_RECEIVER_RET = bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));

    mapping(address => mapping(address => StakeData)) public stakes;

    uint256 public activeStakes;

    uint256 finishedAccumulatingStakeCount;

    mapping(address => uint256) public talentRedeemableRewards;

    mapping(address => uint256) public maxSForTalent;

    bool public disabled;

    address public factory;

    uint256 public tokenPrice;

    uint256 public talentPrice;

    uint256 public totalStableStored;

    uint256 public totalTokensStaked;

    uint256 rewardsAdminWithdrawn;

    uint256 public override(IRewardParameters) totalAdjustedShares;

    uint256 public override(IRewardParameters) rewardsMax;

    uint256 public override(IRewardParameters) rewardsGiven;

    uint256 public override(IRewardParameters) start;

    uint256 public override(IRewardParameters) end;

    uint256 public S;

    uint256 public SAt;

    bool private isAlreadyUpdatingAdjustedShares;

    event Stake(address indexed owner, address indexed talentToken, uint256 talAmount, bool stable);

    event RewardClaim(address indexed owner, address indexed talentToken, uint256 stakerReward, uint256 talentReward);

    event RewardWithdrawal(
        address indexed owner,
        address indexed talentToken,
        uint256 stakerReward,
        uint256 talentReward
    );

    event TalentRewardWithdrawal(address indexed talentToken, address indexed talentTokenWallet, uint256 reward);

    event Unstake(address indexed owner, address indexed talentToken, uint256 talAmount);

    function initialize(uint256 _start,
        uint256 _end,
        uint256 _rewardsMax,
        address _stableCoin,
        address _factory,
        uint256 _tokenPrice,
        uint256 _talentPrice
    ) public virtual initializer {
        require(_tokenPrice > 0, "_tokenPrice cannot be 0");
        require(_talentPrice > 0, "_talentPrice cannot be 0");

        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControlEnumerable_init_unchained();

        __StableThenToken_init(_stableCoin);
        __RewardCalculator_init();

        start = _start;
        end = _end;
        rewardsMax = _rewardsMax;
        factory = _factory;
        tokenPrice = _tokenPrice;
        talentPrice = _talentPrice;
        SAt = _start;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165Upgradeable, AccessControlEnumerableUpgradeable)
    returns (bool)
    {
        return AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }


    function stakeStable(address _talent, uint256 _amount)
    public
    onlyWhileStakingEnabled
    stablePhaseOnly
    updatesAdjustedShares(msg.sender, _talent)
    returns (bool)
    {
        require(_amount > 0, "amount cannot be zero");
        require(!disabled, "staking has been disabled");

        uint256 tokenAmount = convertUsdToToken(_amount);

        totalStableStored += _amount;

        _checkpointAndStake(msg.sender, _talent, tokenAmount);

        IERC20(stableCoin).transferFrom(msg.sender, address(this), _amount);

        emit Stake(msg.sender, _talent, tokenAmount, true);

        return true;
    }

    function claimRewards(address _talent) public returns (bool) {
        claimRewardsOnBehalf(msg.sender, _talent);

        return true;
    }

    function claimRewardsOnBehalf(address _owner, address _talent)
    public
    updatesAdjustedShares(_owner, _talent)
    returns (bool)
    {
        _checkpoint(_owner, _talent, RewardAction.RESTAKE);

        return true;
    }

    function withdrawRewards(address _talent)
    public
    tokenPhaseOnly
    updatesAdjustedShares(msg.sender, _talent)
    returns (bool)
    {
        _checkpoint(msg.sender, _talent, RewardAction.WITHDRAW);

        return true;
    }

    function withdrawTalentRewards(address _talent) public tokenPhaseOnly returns (bool) {
        require(msg.sender == PersonalToken_interface(_talent).talent(), "only the talent can withdraw their own shares");

        uint256 amount = talentRedeemableRewards[_talent];

        IERC20(token).transfer(msg.sender, amount);

        talentRedeemableRewards[_talent] = 0;

        return true;
    }

    function stableCoinBalance() public view returns (uint256) {
        return IERC20(stableCoin).balanceOf(address(this));
    }

    function tokenBalance() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function stakeAvailability(address _talent) public view returns (uint256) {
        require(_isTalentToken(_talent), "not a valid talent token");

        uint256 talentAmount = PersonalToken_interface(_talent).mintingAvailability();

        return convertTalentToToken(talentAmount);
    }

    function swapStableForToken(uint256 _stableAmount) public onlyRole(DEFAULT_ADMIN_ROLE) tokenPhaseOnly {
        require(_stableAmount <= totalStableStored, "not enough stable coin left in the contract");

        uint256 tokenAmount = convertUsdToToken(_stableAmount);
        totalStableStored -= _stableAmount;

        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        IERC20(stableCoin).transfer(msg.sender, _stableAmount);
    }

    function onTransferReceived(
        address, // _operator
        address _sender,
        uint256 _amount,
        bytes calldata data
    ) external override(IERC1363ReceiverUpgradeable) onlyWhileStakingEnabled returns (bytes4) {
        if (_isToken(msg.sender)) {
            require(!disabled, "staking has been disabled");

            address talent = bytesToAddress(data);

            _checkpointAndStake(_sender, talent, _amount);

            emit Stake(_sender, talent, _amount, false);

            return ERC1363_RECEIVER_RET;
        } else if (_isTalentToken(msg.sender)) {
            require(_isTokenSet(), "TAL token not yet set. Refund not possible");

            address talent = msg.sender;

            uint256 tokenAmount = _checkpointAndUnstake(_sender, talent, _amount);

            emit Unstake(_sender, talent, tokenAmount);

            return ERC1363_RECEIVER_RET;
        } else {
            revert("Unrecognized ERC1363 token received");
        }
    }

    function _isToken(address _address) internal view returns (bool) {
        return _address == token;
    }

    function _isTalentToken(address _address) internal view returns (bool) {
        return PersonalFactory_interface(factory).isTalentToken(_address);
    }

    function totalShares() public view override(IRewardParameters) returns (uint256) {
        return totalTokensStaked;
    }

    function rewardsLeft() public view override(IRewardParameters) returns (uint256) {
        return rewardsMax - rewardsGiven - rewardsAdminWithdrawn;
    }

    function disable() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!disabled, "already disabled");

        _updateS();
        disabled = true;
    }

    function adminWithdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(disabled || block.timestamp < end, "not disabled, and not end of staking either");
        require(activeStakes == 0, "there are still stakes accumulating rewards. Call `claimRewardsOnBehalf` on them");

        uint256 amount = rewardsLeft();
        require(amount > 0, "nothing left to withdraw");

        IERC20(token).transfer(msg.sender, amount);
        rewardsAdminWithdrawn += amount;
    }

    function setTokenPrice(uint256 _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenPrice = _price;
    }

    function _checkpointAndStake(
        address _owner,
        address _talent,
        uint256 _tokenAmount
    ) private updatesAdjustedShares(_owner, _talent) {
        require(_isTalentToken(_talent), "not a valid talent token");
        require(_tokenAmount > 0, "amount cannot be zero");

        _checkpoint(_owner, _talent, RewardAction.RESTAKE);
        _stake(_owner, _talent, _tokenAmount);
    }

    function _checkpointAndUnstake(
        address _owner,
        address _talent,
        uint256 _talentAmount
    ) private updatesAdjustedShares(_owner, _talent) returns (uint256) {
        require(_isTalentToken(_talent), "not a valid talent token");

        StakeData storage stake = stakes[_owner][_talent];

        bool isFullRefund = stake.talentAmount == _talentAmount;

        if (isFullRefund) {
            _checkpoint(_owner, _talent, RewardAction.WITHDRAW);
        } else {
            _checkpoint(_owner, _talent, RewardAction.RESTAKE);
        }

        stake = stakes[_owner][_talent];

        require(stake.lastCheckpointAt > 0, "stake does not exist");
        require(stake.talentAmount >= _talentAmount);

        uint256 proportion = (_talentAmount * MUL) / stake.talentAmount;
        uint256 tokenAmount = (stake.tokenAmount * proportion) / MUL;

        require(IERC20(token).balanceOf(address(this)) >= tokenAmount, "not enough TAL to fulfill request");

        stake.talentAmount -= _talentAmount;
        stake.tokenAmount -= tokenAmount;
        totalTokensStaked -= tokenAmount;

        if (stake.tokenAmount == 0 && !stake.finishedAccumulating) {
            stake.finishedAccumulating = true;

            activeStakes -= 1;
        }

        _burnTalent(_talent, _talentAmount);
        _withdrawToken(_owner, tokenAmount);

        return tokenAmount;
    }

    function _stake(
        address _owner,
        address _talent,
        uint256 _tokenAmount
    ) private {
        uint256 talentAmount = convertTokenToTalent(_tokenAmount);

        StakeData storage stake = stakes[_owner][_talent];

        if (stake.tokenAmount == 0) {
            activeStakes += 1;
            stake.finishedAccumulating = false;
        }

        stake.tokenAmount += _tokenAmount;
        stake.talentAmount += talentAmount;

        totalTokensStaked += _tokenAmount;

        _mintTalent(_owner, _talent, talentAmount);
    }

    function _checkpoint(
        address _owner,
        address _talent,
        RewardAction _action
    ) private updatesAdjustedShares(_owner, _talent) {
        StakeData storage stake = stakes[_owner][_talent];

        _updateS();

        address talentAddress = PersonalToken_interface(_talent).talent();

        uint256 maxS = (maxSForTalent[_talent] > 0) ? maxSForTalent[_talent] : S;

        (uint256 stakerRewards, uint256 talentRewards) = calculateReward(
            stake.tokenAmount,
            stake.S,
            maxS,
            stake.talentAmount,
            IERC20(_talent).balanceOf(talentAddress)
        );

        rewardsGiven += stakerRewards + talentRewards;
        stake.S = maxS;
        stake.lastCheckpointAt = block.timestamp;

        talentRedeemableRewards[_talent] += talentRewards;

        if (disabled && !stake.finishedAccumulating) {
            stake.finishedAccumulating = true;
            activeStakes -= 1;
        }

        if (stakerRewards == 0) {
            return;
        }

        if (_action == RewardAction.WITHDRAW) {
            IERC20(token).transfer(_owner, stakerRewards);
            emit RewardWithdrawal(_owner, _talent, stakerRewards, talentRewards);
        } else if (_action == RewardAction.RESTAKE) {
            uint256 availability = stakeAvailability(_talent);
            uint256 rewardsToStake = (availability > stakerRewards) ? stakerRewards : availability;
            uint256 rewardsToWithdraw = stakerRewards - rewardsToStake;

            _stake(_owner, _talent, rewardsToStake);
            emit RewardClaim(_owner, _talent, rewardsToStake, talentRewards);

            if (rewardsToWithdraw > 0 && token != address(0x0)) {
                IERC20(token).transfer(_owner, rewardsToWithdraw);
                emit RewardWithdrawal(_owner, _talent, rewardsToWithdraw, 0);
            }
        } else {
            revert("Unrecognized checkpoint action");
        }
    }

    function _updateS() private {
        if (disabled) {
            return;
        }

        if (totalTokensStaked == 0) {
            return;
        }

        S = S + (calculateGlobalReward(SAt, block.timestamp)) / totalAdjustedShares;
        SAt = block.timestamp;
    }

    function calculateEstimatedReturns(
        address _owner,
        address _talent,
        uint256 _currentTime
    ) public view returns (uint256 stakerRewards, uint256 talentRewards) {
        StakeData storage stake = stakes[_owner][_talent];
        uint256 newS;

        if (maxSForTalent[_talent] > 0) {
            newS = maxSForTalent[_talent];
        } else {
            newS = S + (calculateGlobalReward(SAt, _currentTime)) / totalAdjustedShares;
        }
        address talentAddress = PersonalToken_interface(_talent).talent();
        uint256 talentBalance = IERC20(_talent).balanceOf(talentAddress);

        (uint256 sRewards, uint256 tRewards) = calculateReward(
            stake.tokenAmount,
            stake.S,
            newS,
            stake.talentAmount,
            talentBalance
        );

        return (sRewards, tRewards);
    }

    function _mintTalent(
        address _owner,
        address _talent,
        uint256 _amount
    ) private {
        PersonalToken_interface(_talent).mint(_owner, _amount);

        if (maxSForTalent[_talent] == 0 && PersonalToken_interface(_talent).mintingFinishedAt() > 0) {
            maxSForTalent[_talent] = S;
        }
    }

    function _burnTalent(address _talent, uint256 _amount) private {
        PersonalToken_interface(_talent).burn(address(this), _amount);
    }

    function _withdrawToken(address _owner, uint256 _amount) private {
        IERC20(token).transfer(_owner, _amount);
    }

    modifier updatesAdjustedShares(address _owner, address _talent) {
        if (isAlreadyUpdatingAdjustedShares) {
            _;
        } else {
            isAlreadyUpdatingAdjustedShares = true;
            uint256 toDeduct = sqrt(stakes[_owner][_talent].tokenAmount);

            _;

            totalAdjustedShares = totalAdjustedShares + sqrt(stakes[_owner][_talent].tokenAmount) - toDeduct;
            isAlreadyUpdatingAdjustedShares = false;
        }
    }

    modifier onlyWhileStakingEnabled() {
        require(block.timestamp >= start, "staking period not yet started");
        require(block.timestamp <= end, "staking period already finished");
        _;
    }

    function convertUsdToToken(uint256 _usd) public view returns (uint256) {
        return (_usd * 1 ether) / tokenPrice;
    }

    function convertTokenToTalent(uint256 _tal) public view returns (uint256) {
        return (_tal * 1 ether) / talentPrice;
    }

    function convertTalentToToken(uint256 _talent) public view returns (uint256) {
        return (_talent * talentPrice) / 1 ether;
    }

    function convertUsdToTalent(uint256 _usd) public view returns (uint256) {
        return convertTokenToTalent(convertUsdToToken(_usd));
    }

    function bytesToAddress(bytes memory bs) private pure returns (address addr) {
        require(bs.length == 20, "invalid data length for address");

        assembly {
            addr := mload(add(bs, 20))
        }
    }
}
