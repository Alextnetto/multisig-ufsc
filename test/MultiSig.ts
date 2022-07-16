import { expect } from "chai";
import { Wallet } from "ethers";
import { ethers } from "hardhat";
import { MultiSig, MultiSig__factory } from "../typechain";

describe("MultiSig", function () {
  let multiSig: MultiSig
  let signer0: Wallet
  let signer1: Wallet

  describe("constructor checks", () => {
    let multiSigFactory: MultiSig__factory
    let multiSig: Promise<MultiSig>

    beforeEach('load contract', async () => {
      multiSigFactory = await ethers.getContractFactory("MultiSig");
      [signer0, signer1] = await (ethers as any).getSigners()
    })

    it("fails if no address provided", async function () {
      multiSig = multiSigFactory.deploy([], 1);
      await expect(multiSig).to.be.revertedWith("signers required")
    });

    it("fails if no min required signatures == 0", async function () {
      multiSig = multiSigFactory.deploy([signer0.address], 0);
      await expect(multiSig).to.be.revertedWith("require minimum signatures to approve transactions")
    });

    it("fails if min required signatures > n of signers", async function () {
      multiSig = multiSigFactory.deploy([signer0.address, signer1.address], 3);
      await expect(multiSig).to.be.revertedWith("number of signers need to be > than min required signatures")
    });

    it("fails if a signer is 0x0", async function () {
      multiSig = multiSigFactory.deploy([signer0.address, signer1.address, ethers.constants.AddressZero], 1);
      await expect(multiSig).to.be.reverted
    });
  });
})

