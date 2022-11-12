#!/usr/bin/python3

import brownie
from web3 import Web3
from conftest import hashed_email, hashed_git


def test_returns_usr_id(accounts, sbt):
    sbt.setAchevementsContractAddress(accounts[2]);
    sbt.mint(accounts[1], 123, {'from': accounts[0]})
    sbt.claim([hashed_git, hashed_email], {'from': accounts[1]})
    assert sbt.getUserId(accounts[1], {'from' : accounts[2]}) == 123

