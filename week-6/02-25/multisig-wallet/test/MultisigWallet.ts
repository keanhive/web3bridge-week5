import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { MultisigWallet } from "../typechain-types";

describe("MultisigWallet", function () {
    let wallet: MultisigWallet;
    let owner1: SignerWithAddress;
    let owner2: SignerWithAddress;
    let owner3: SignerWithAddress;
    let nonOwner: SignerWithAddress;

    beforeEach(async function () {
        [owner1, owner2, owner3, nonOwner] = await ethers.getSigners();
        const owners: [string, string, string] = [owner1.address, owner2.address, owner3.address];
        const MultisigWallet = await ethers.getContractFactory("MultisigWallet");
        wallet = await MultisigWallet.deploy(owners);
        await wallet.waitForDeployment();
    });

    it("Should set owners", async function () {
        const owners = await wallet.getOwners();
        expect(owners[0]).to.equal(owner1.address);
        expect(owners[1]).to.equal(owner2.address);
        expect(owners[2]).to.equal(owner3.address);
    });

    it("Should accept deposits from anyone", async function () {
        const amount = ethers.parseEther("1");
        await expect(
            nonOwner.sendTransaction({ to: await wallet.getAddress(), value: amount })
        ).to.changeEtherBalance(await wallet.getAddress(), amount);
    });

    it("Should require 2 signatures for withdrawal", async function () {
        const deposit = ethers.parseEther("2");
        const withdraw = ethers.parseEther("1");
        const walletAddress = await wallet.getAddress();

        await owner1.sendTransaction({ to: walletAddress, value: deposit });
        await wallet.connect(owner1).submitTransaction(owner2.address, withdraw, "0x");

        await wallet.connect(owner1).confirmTransaction(0);
        await expect(wallet.connect(owner1).executeTransaction(0)).to.be.revertedWith("Need 2 signatures");

        await wallet.connect(owner2).confirmTransaction(0);
        await expect(wallet.connect(owner1).executeTransaction(0)).to.changeEtherBalance(walletAddress, -withdraw);
    });
});