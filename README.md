# RASSIFAB

The following dependencies are required to run RASSIFAB:

1- Geth client v1.8.27 (Go implementation of Ethereum)

2- Solidity compiler >=0.7.0 <0.9.0

3- Node.js v10.19.0

4- Web3.js library v1.7.0

In the file "genesis.json" you will find the blockchain set up that indicates the configuration of the local Ethereum-based test network (network id, gas limit, consensus algorithm, sealer nodes' addresses, prefunded accounts, etc.). 

However, it's possible to automatically generate a new one using puppeth (a tool provided by Ethereum) while configuring your own local Ethereum blockchain. 

Thus, make sure to include the right addresses of your local accounts that you must have already generated with their respective keys used for signing.

Before deploying the smart contracts (i.e., SIsInit.sol and SIsFirmware.sol) to your local blockchain, you need to generate the .abi and .bin files by compiling the contracts using the solidity compiler. Then change the corresponding data on the deployment scripts (i.e., DeployInitSC.js and DeployFWSC.js). 

In addition, the accounts used and their corresponding addresses depend also on the local blockchain. Therefore, make sure to change those within the scripts according to you own network setting. 
