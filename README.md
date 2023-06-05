# RASSIFAB

The following dependencies are required to run RASSIFAB:

1- Geth client (Go implementation of Ethereum https://geth.ethereum.org/)

2- Solidity compiler >=0.7.0 <0.9.0

3- Node.js 

In the file "genesis.json" you will find the blockchain set up that indicates the configuration of the local Ethereum-based test network (network id, gas limit, consensus algorithm, sealer nodes' addresses, prefunded accounts, etc.). However, it's possible to generate a new genesis file using puppeth (a tool provided by Ethereum) while configuring your own local blockchain. Thus, make sure to include the right addresses of your local accounts that you must have already generated with their respective keys used for signing.

Before deploying the smart contracts (i.e., SIsInit.sol and SIsFirmware.sol) to your local blockchain, you need to generate the .abi and .bin files by compiling the contracts using the solidity compiler. Then change the network data on the deployment scripts (i.e., DeployInitSC.js and DeployFWSC.js). In addition, the accounts used and their corresponding addresses depend also on the local blockchain. Therefore, make sure to change those within the scripts according to your own network setting. 
