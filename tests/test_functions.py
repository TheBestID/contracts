#!/usr/bin/python3

import brownie
from web3 import Web3
from conftest import hashed_email, hashed_git


# def test_returns_usr_id(accounts, sbt):
#     sbt.setAchevementsContractAddress(accounts[2])
#     sbt.mint(accounts[1], 123, {'from': accounts[0]})
#     sbt.claim([hashed_git, hashed_email], {'from': accounts[1]})
#     assert sbt.getUserId(accounts[1], {'from' : accounts[2]}) == 123

def test_achievement_mint(accounts, sbt, achievement):
    sbt.setAchevementsContractAddress(achievement.address)
    achievement.setSBTContractAddress(sbt.address)
    sbt.mint(accounts[1], 123, {'from': accounts[0]})
    sbt.claim([hashed_git, hashed_email], {'from': accounts[1]})
    # with brownie.no_revert():
    # assert sbt.getUserId(accounts[1], {'from': achievement.address}) == 123
    achievement.mint([0, 0, 123, False, 0, False, 0, False, "0"], {'from' : accounts[1]})
    assert True
