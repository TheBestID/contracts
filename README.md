# SoulDev contracts on Ethereum

## Main info
Main part consists of two contracts - `sbt.sol` and `sbt-achievements.sol`. 

First one is implementation of soul bounded token as is, which user can get after completing his registration on our platform. This token represents user in our ecosystem as a Soul. 

Second is contract of achievements. Any Soul can mint an achievement and give it to any other Soul. Currently there is one Achievement type with customisable data. We are working on implementing a system with many Achievement contracts that can be written by users and will inherit a single template.

## Contracts features, capabilities and their implementation
### [SBT](contracts/sbt.sol) 
- `mint` - mints SBT for user. It can only be called by our platform, because user must be verified there.
- `claim` - user must claim his Soul and store his data there in hashed format. Otherwise Soul wouldn't exist.
- `burn` - the user can burn his Soul anytime he wants. Note that the Soul must be claimed to be burned.
- `getSoulData` - allows user to verify, that their data stored in our app is it's own and it didn't change.

### [Achievements](contracts/sbt-achievements.sol)
- Data stored in Achievement:
    - `achievement_id`, `achievement_type` - our platform needs this information to display achievements correctly.
    - `issuer` - Soul that mints an Achievement.
    - `owner` - owner/recipient of Achievement.
    - `verifier` - Soul that can verify Achievement (e.g. the the company can confirm that someone worked for them by verifying their achievement).
    - `is_accepted` - an achievement can only be accepted once, so we need to track whether it has already been accepted or not. Same for verifying and `is_verified`.
- `mint` - mints Achievement for user. It can be minted by any user and "sent" to any other Soul. Soul must exist to create Achievement or to receive it.
- `burn` - the user can burn his Achievement anytime he wants. Achievement must be claimed to be burned.
- `setOwner` - issuer can set the owner even if he had already minted an Achievement.
- `acceptAchievement` - owner must accept his Achievement - unless it wouldn't be displayed.
- `verifyAchievement` - made for verifier to verify Achievement. Only Achievement's verifier can verify Achievement.
- `splitAchievement` - verifier can split Achievement between few Souls.
- `getAchievementInfo` - issuer, owner or verifier can get Achievement data.
- `replenishAchievementBalance` - anyone can replenish Achievement balance.
