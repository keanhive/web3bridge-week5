import { ethers } from "hardhat";

async function main() {
    const signers = await ethers.getSigners();

    const owners: [string, string, string] = [
        signers[0].address,
        signers[1].address,
        signers[2].address
    ];

    console.log("Deploying with owners:");
    console.log(owners[0]);
    console.log(owners[1]);
    console.log(owners[2]);

    const MultisigWallet = await ethers.getContractFactory("MultisigWallet");
    const multisigWallet = await MultisigWallet.deploy(owners);
    await multisigWallet.waitForDeployment();

    const address = await multisigWallet.getAddress();
    console.log("Deployed to:", address);
}

main().catch(console.error);