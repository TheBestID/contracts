#!/usr/bin/python3

from brownie import SBT, accounts


def main():
    return SBT.deploy({'from': accounts[0]})
