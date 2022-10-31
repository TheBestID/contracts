const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("SBT", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  async function deploySBT() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const SBT = await ethers.getContractFactory("SBT");
    const sbt = await SBT.deploy();

    return { sbt, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set operator to msg.sender", async function () {
      const { sbt, owner } = await loadFixture(deploySBT);

      expect(await sbt.operator()).to.equal(owner.address);
    });

    it("Should correctly mint SBT for msg.sender", async function () {
      const { sbt, owner, otherAccount } = await loadFixture(deploySBT);
      const my_data = {url : "my_url", github_url : "my_github", email_address : "my_email"};
      await sbt.mint(otherAccount.address, 1, "my_url");
      expect(await sbt.getOwner(1)).to.be.equal(otherAccount.address);
    });
  });

});
