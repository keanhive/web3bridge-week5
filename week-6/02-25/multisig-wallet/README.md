# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```
npm install --save-dev dotenv

npx hardhat run scripts/deploy-lisk.ts --network lisk-sepolia

[dotenv@17.3.1] injecting env (1) from .env -- tip: ⚙️  override existing env vars with { override: true }
[dotenv@17.3.1] injecting env (0) from .env -- tip: 🔐 encrypt with Dotenvx: https://dotenvx.com
[dotenv@17.3.1] injecting env (0) from .env -- tip: ⚙️  load multiple .env files with { path: ['.env.local', '.env'] }
🚀 Deploying 2-of-3 Multisig Wallet to Lisk Sepolia...
Deploying from: 0xab80da89E733Ea48Aa3607A6c50d870C3588Ea88
Account balance: 0.019986389313711446 ETH

📋 Setting owners:
1: 0xab80da89E733Ea48Aa3607A6c50d870C3588Ea88
2: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
3: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
🔐 Required signatures: 2

⏳ Deploying...

✅ Multisig Wallet deployed to: 0xa2096E054b5AB96114dfC7613671b0A80DdDAFe8
🔗 BlockScout: https://sepolia-blockscout.lisk.com/address/0xa2096E054b5AB96114dfC7613671b0A80DdDAFe8
💰 Contract balance: 0.0 ETH

📋 Verified owners on contract:
1: 0xab80da89E733Ea48Aa3607A6c50d870C3588Ea88
2: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
3: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
![img.png](img.png)