// Library Imports
const Web3 = require('web3');
const EthereumTx = require('ethereumjs-tx').Transaction;

// Connection Initialization
const rpcURL = "http://localhost:8505";
const web3 = new Web3(rpcURL);
const fs = require('fs');
const prompt = require("prompt-sync")();

// Data set up
let abi = fs.readFileSync("./Contracts/SIsFirmware.abi", 'utf8');

const mycontract = new web3.eth.Contract(JSON.parse(abi), '0x1a2Ac08Bfdf7be85065cF2f8d1Ba71467Dd0de51',{handleRevert: true})

let account = '0x920eb037b7ce3b295fc498a936795c05f2ca44f3';

let parameter = {
    from: account,
    gas: web3.utils.toHex(9000000),
    gasPrice: web3.utils.toHex(web3.utils.toWei('30', 'gwei'))
};

const input1 = prompt("What is the ID of the device? ");

const input2 = prompt("What is the address of the device? ");

const input3 = prompt("What is your own address? ");

const input4 = prompt("What is the hash of the current firmware installed on the device? ");

const input5 = prompt("What is the hash of its IPFS link? ");

const input6 = prompt("What is the version of the firmware? ");

console.time('Execution time');
mycontract.methods.UpdateMap_DFW(input1,input2,input3,input4,input5,input6).send(parameter)
.on('transactionHash', function(hash){ 
//console.log(hash);
})
.on('confirmation', function(confirmationNumber, receipt){
//console.log(confirmationNumber);
})
.on('receipt', function(receipt){
console.timeEnd('Execution time');
console.log("Mapping updated succesfully!");
})
.on('error', function(error, receipt) {
console.log("Failed with error: " + error.reason);
});    
