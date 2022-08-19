// Library Imports
const Web3 = require('web3');
const EthereumTx = require('ethereumjs-tx').Transaction;

// Connection Initialization
const rpcURL = "http://localhost:8503"; //8505
const web3 = new Web3(rpcURL);
const fs = require('fs');
const prompt = require("prompt-sync")();

// Data set up
let abi = fs.readFileSync("./Contracts/SIsInit.abi", 'utf8');

const mycontract = new web3.eth.Contract(JSON.parse(abi), '0x2eFd4D91Bf8199342dD7bfe977eFb4569418C619',{handleRevert: true})

let account = '0xd366f218b163c16749302df0c3a99fe4bd63dbe6';


let parameter = {
    from: account,
    gas: web3.utils.toHex(9000000),
    gasPrice: web3.utils.toHex(web3.utils.toWei('30', 'gwei'))
}

const input1 = prompt("Please enter the address of the device you want to add: ");

const input2 = prompt("What is the ID of the OEM of the device? ");

const input3 = prompt("What is the ID of the DERA of the device? ");

const input4 = prompt("What is the serial number of the device? ");

const input5 = prompt("What is the type of the device? ");

console.time('Execution time');
mycontract.methods.addDevice(input1,input2,input3,input4,input5).send(parameter)
.on('transactionHash', function(hash){ 
//console.log(hash);
})
.on('confirmation', function(confirmationNumber, receipt){
//console.log(confirmationNumber);
})
.on('receipt', function(receipt){
console.timeEnd('Execution time');
console.log("Device added succesfully!");
})
.on('error', function(error, receipt) {
console.log("Failed with error: " + error.reason);
});   
