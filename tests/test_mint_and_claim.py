#!/usr/bin/python3

import pytest
import brownie
from web3 import Web3
from conftest import hashed_email, hashed_git


def test_can_claim_only_minted(accounts, sbt):
    with brownie.reverts("Non minted soul"):
        sbt.claim([hashed_git, hashed_email], {'from': accounts[1]})

def test_successfully_mints_and_claims(accounts, sbt):
    sbt.mint(accounts[1], 123, {'from': accounts[0]})
    sbt.claim([hashed_git, hashed_email], {'from': accounts[1]})
    with brownie.reverts("Non minted soul"):
        sbt.claim([hashed_git, hashed_email], {'from': accounts[2]})
    with brownie.reverts("Soul is already claimed"):
        sbt.claim([hashed_git, hashed_email], {'from': accounts[1]})

    # assert sbt.hasSoul(accounts[1]) == True
    # assert sbt.getSoul(accounts[1])[0] == 123


def test_stores_correct_data(accounts, sbt):
    sbt.mint(accounts[1], 123, {'from': accounts[0]})
    sbt.claim([hashed_git, hashed_email], {'from': accounts[1]})
    assert sbt.hasSoul(accounts[1]) == True
    assert sbt.getSoul(accounts[1])[0] == 123
    assert sbt.getSoul(accounts[1])[1][0] == Web3.toHex(hashed_git)
    assert sbt.getSoul(accounts[1])[1][1] == Web3.toHex(hashed_email)


def test_throws_if_sbt_exists(accounts, sbt):
    sbt.mint(accounts[1], 1, {'from': accounts[0]})
    with brownie.reverts("Soul is minted, but not claimed"):
        sbt.mint(accounts[1], 1, {'from': accounts[0]})
    sbt.claim([hashed_git, hashed_email], {'from': accounts[1]})
    with brownie.reverts("Soul exists"):
        sbt.mint(accounts[1], 1, {'from': accounts[0]})

    # assert sbt.hasSoul(accounts[1]) == True


def test_only_operator_mints(accounts, sbt):
    with brownie.reverts("Only operator can mint new souls"):
        sbt.mint(accounts[1], 1,
                 {'from': accounts[1]})
