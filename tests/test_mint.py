#!/usr/bin/python3

import pytest

def test_sender_balance_decreases(accounts, sbt):
    sbt.mint(accounts[1], 1, ['my_url', '2', '3'], {'from': accounts[0]})
    # sbt.mint(accounts[1], 1, {'url' : 'my_url', 'github_url' : '2', 'email_address' : '3'}, {'from': accounts[0]})
    assert sbt.hasSoul(accounts[1]) == True
