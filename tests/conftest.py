#!/usr/bin/python3

import pytest
from web3 import Web3

hashed_git = Web3.solidityKeccak(
    ['bytes32'], [bytes('my_git'.encode())])
hashed_email = Web3.solidityKeccak(
    ['bytes32'], [bytes('my_email'.encode())])

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass


@pytest.fixture(scope="module")
def sbt(SBT, accounts):
    return SBT.deploy({'from': accounts[0]})
