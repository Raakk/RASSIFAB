// Library Imports
const Web3 = require('web3');
const EthereumTx = require('ethereumjs-tx').Transaction;

// Connection Initialization
const rpcURL = "http://localhost:8501";
const web3 = new Web3(rpcURL);
const fs = require('fs');
const prompt = require("prompt-sync")();

// Data set up
let abi = fs.readFileSync("./Contracts/SIsInit.abi", 'utf8');

const mycontract = new web3.eth.Contract(JSON.parse(abi), '0x2eFd4D91Bf8199342dD7bfe977eFb4569418C619',{handleRevert: true})

let account = '0x15cd9022b0dd503fc2065ceea8da89ece9d4b2cf';

let parameter = {
    from: account,
    gas: web3.utils.toHex(9000000),
    gasPrice: web3.utils.toHex(web3.utils.toWei('30', 'gwei'))
}

const input1 = prompt("Please enter the ID of the DSO: ");

const input2 = prompt("Please enter the address of the DSO node you want to add: ");

console.time('Execution time');
mycontract.methods.DERANUpdate(input1,input2).send(parameter)
.on('transactionHash', function(hash){ 
//console.log(hash);
})
.on('confirmation', function(confirmationNumber, receipt){
//console.log(confirmationNumber);
})
.on('receipt', function(receipt){
console.timeEnd('Execution time');
console.log("DERA Node added successfully!");
})
.on('error', function(error, receipt) {
console.log("Failed with error: " + error.reason);
});  
