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
let abi = fs.readFileSync("./Contracts/SIsInit.abi", 'utf8');

const mycontract = new web3.eth.Contract(JSON.parse(abi), '0x2eFd4D91Bf8199342dD7bfe977eFb4569418C619')


mycontract.events.allEvents()
.on('data', (event) => {
	console.log(event.returnValues);
})
.on('error', console.error);
      
