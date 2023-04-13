// Library Imports
const Web3 = require('web3');
const EthereumTx = require('ethereumjs-tx').Transaction;
const fs = require('fs');

// Connection Initialization

const provider = new Web3.providers.WebsocketProvider('ws://localhost:8545', {
  headers: {
    Origin: "mine"
  }
});
let web3 = new Web3(provider);

// Data set up
let abi = fs.readFileSync("./Contracts/SIsFirmware.abi", 'utf8');

const mycontract = new web3.eth.Contract(JSON.parse(abi), '0x1a2Ac08Bfdf7be85065cF2f8d1Ba71467Dd0de51')


//mycontract.events.allEvents()

mycontract.events.Mapping_updated()
.on('data', (event) => {
	console.log("Mapping updated");
})
.on('error', console.error);

mycontract.events.Status()
.on('data', (event) => {
	console.log("The status of firmware update of the device with the address: " + event.returnValues[1] + " is: " + web3.utils.hexToAscii(event.returnValues[2]));
})
.on('error', console.error);

mycontract.events.New_Firmware_Update()
.on('data', (event) => {
	console.log("Firmware update request sent with the following metadata" +"\n"+ "Hash of firmware: " + event.returnValues[3] + "\n" +"IPFS link: " + event.returnValues[4]+ "\n" + "Secret key: " + event.returnValues[5]);
})
.on('error', console.error);

mycontract.events.Wrong_FW_Metadata()
.on('data', (event) => {
	console.log("The following node sent wrong firmware data: " + event.returnValues[1]);
})
.on('error', console.error);

mycontract.events.FW_Updated()
.on('data', (event) => {
	console.log(event.returnValues);
})
.on('error', console.error);
      
