# #!/usr/bin/python3

# import brownie
# from web3 import Web3
# from conftest import hashed_email, hashed_git


# def test_successfully_burns(accounts, sbt):
#     sbt.mint(accounts[1], 123, [hashed_git, hashed_email],
#              {'from': accounts[0]})
#     sbt.burn({'from': accounts[1]})
#     assert sbt.hasSoul(accounts[1]) == False


# def test_reverts_burning_empty(accounts, sbt):
#     with brownie.reverts("Soul doesn't exist"):
#         sbt.burn({'from': accounts[1]})


# def test_reverts_access_burned_data(accounts, sbt):
#     sbt.mint(accounts[1], 123, [hashed_git, hashed_email],
#              {'from': accounts[0]})
#     sbt.burn({'from': accounts[1]})
#     with brownie.reverts("Soul doesn't exist"):
#         sbt.getSoul(accounts[1])

# # def test_deletes_burned_data(accounts, sbt):
#     # TODO
