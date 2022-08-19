// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./SIsInit.sol";

contract SIsFirmware {

//********************************************************Data Structures & Modifiers**********************************************************************************

    struct Firmware {
        uint version; //the version of the firmware
        bytes32 hash; //the hash of the firmware
        bytes32 tmphash; //used to verify the provided hash by other OEMNs during the update procedure on-chain
        bytes32 IPFS_Path; //Path to upload the firmware from the InterPlanetary File System
        bytes32 tmpIPFS_Path; //used to verify the provided IPFS path by other OEMNs during the update procedure on-chain
        bool updated; //status of the firmware (up-to-date = true, otherwise false)
        address[] signers; //used to restrict signing during the firmware update procedure (only once for each OEMNs)
    }    

    mapping(address => bool) public Black_List; //mapping of all blacklisted OEMNs

    mapping(address => Firmware) public deviceFW; //mapping of all devices' addresses and their firmware metadata

    mapping(address => bool) public List; //used to verify that the mapping of devices is done only once to avoid duplication

    SIsInit public sc; //instance of the deployed initialization contract (i.e., SIsInit.sol)

    //ensures that the account of the OEMN is not blacklisted
    modifier NotBlackListed() {
        if (Black_List[msg.sender])
        revert('You are blacklisted :(');
        _;
    }

    //ensures that the mapping of devices and their firmware metadata is executed only once
    modifier onlyOnce(address add) {
        if (List[add])
        revert('Device already added!');
        _;
    }

    //checks if the OEMN already signed a transaction to push for a new firmware update or patch for a device
    modifier CheckIfSigned(address add) {
        uint tmp = 0;
        for (uint i = 0; i < deviceFW[add].signers.length; i++) {
            if (deviceFW[add].signers[i] == msg.sender) {
                tmp = 1;
                break;
            }
        }
        if (tmp == 1)
             revert('You already signed!');
             _;    
    }

//************************************************************Smart Contract Constructor, Functions & Events*************************************************************

    //initialize the instance of the SIsInit.sol contract with its deployment address
    constructor () {
        sc = SIsInit(0x2eFd4D91Bf8199342dD7bfe977eFb4569418C619); //uses the address of the SIsInit contract obtained after it has been deployed on-chain
    }

    //issues a notification to indicate that an OEMN updated the mapping of the device and its current firmware metadata
    event Mapping_updated(bytes8 indexed OEM, address device, address oem);

    //used to update the mapping between a device and its firmware metadata
    function UpdateMap_DFW(uint id, address add_d, address add_OEM, bytes32 fw, bytes32 ipfs, uint v) public NotBlackListed() onlyOnce(add_d){
        require(msg.sender == add_OEM, "Wrong OEM @");
        require(sc.checkID(id,add_d), "Mismatch of ID and @");
        bytes8 manuf = sc.getOEMofSD(id);
        require(sc.checkManuf(manuf, add_OEM), "Unauthorized access!");
        deviceFW[add_d] = Firmware(v, fw, fw, ipfs, ipfs, true, new address[](0));
        List[add_d] = true;
        emit Mapping_updated(manuf, add_d, add_OEM);
    }

     //issues a notification once a firmware update is signed by the majority of OEMNs
    event New_Firmware_Update(address indexed device, bytes8 indexed OEM, bytes8 indexed DERA, bytes32 hash, bytes32 ipfs_link, uint version);
    
    //issues a notification that an OEMN was added to the blacklist
    event Blacklisted(bytes8 indexed OEM, address indexed OEMN_add);

    //issues a notification indicating that the metadata provided is wrong
    event Wrong_FW_Metadata(bytes8 indexed OEM, address indexed add);

    //indicates the status of the update/patch
    event Status(bytes8 indexed OEM, address indexed add, bytes32 stat);
 
    //sends the firmware update (i.e., trigger Firmware_update event) only after the majority of the OEM nodes has validated the hashes
    function sendFWupdate(uint id, address add, address add_OEM, bytes32 hashFW, bytes32 FW_IPFS, uint v) public NotBlackListed() CheckIfSigned(add){
        require(msg.sender == add_OEM, "Wrong OEM @");
        require(sc.checkID(id,add), "Mismatch of ID and @");
        bytes8 manuf = sc.getOEMofSD(id);
        require(sc.checkManuf(manuf, add_OEM), "Unauthorized access!");
        require(deviceFW[add].version < v, "Firmware Downgrade attack!");
        if(deviceFW[add].signers.length == 0) {
            deviceFW[add].tmphash = hashFW; 
            deviceFW[add].tmpIPFS_Path = FW_IPFS;
            deviceFW[add].updated = false;
            deviceFW[add].signers.push(add_OEM);
            sc.setDflag(id, true);
            emit Status(manuf, add, "Waiting for others...");
        }
        else {
            if(deviceFW[add].tmphash != hashFW || deviceFW[add].tmpIPFS_Path != FW_IPFS) {
                sc.deduct_Rep(add_OEM); 
                uint rep = sc.get_Rep(add_OEM);
                if(rep == 0) { 
                    Black_List[add_OEM] = true;
                    emit Blacklisted(manuf, add_OEM);
                }
                emit Wrong_FW_Metadata(manuf, add_OEM);
            }
            else {
                deviceFW[add].signers.push(add_OEM);
                uint count = sc.countManufNodes(manuf);
                if (deviceFW[add].signers.length > (count/2)) {
                    bytes8 dso = sc.getDSOofSD(id);
                    emit New_Firmware_Update(add, manuf, dso, hashFW, FW_IPFS, v);
                }
                else {
                    emit Status(manuf, add, "Waiting for others...");
                }
            }    
        }
    }

     //issues a notification once a firmware patch is signed by the majority of OEMNs
    event New_Firmware_Patch(address indexed device, bytes8 indexed OEM, bytes8 indexed DERA, bytes32 hash, bytes32 ipfs_link, uint version);

    //sends the firmware patch (i.e., trigger Firmware_patch event) only after the majority of the OEM nodes has validated the hashes
    function sendFWpatch(uint id, address add, address add_OEM, bytes32 hashFWP, bytes32 FWP_IPFS, uint v) public NotBlackListed() CheckIfSigned(add){
        require(msg.sender == add_OEM, "Wrong OEM node @");
        require(sc.checkID(id,add), "Mismatch of ID and @");
        bytes8 manuf = sc.getOEMofSD(id);
        require(sc.checkManuf(manuf, add_OEM), "Unauthorized access!");
        require(deviceFW[add].version == v, "Wrong firmware version");
        if(deviceFW[add].signers.length == 0) {
            deviceFW[add].tmphash = hashFWP; 
            deviceFW[add].tmpIPFS_Path = FWP_IPFS;
            deviceFW[add].updated = false;
            deviceFW[add].signers.push(add_OEM);
            sc.setDflag(id, true);
            emit Status(manuf, add, "Waiting for others...");
        }
        else {
            if(deviceFW[add].tmphash != hashFWP || deviceFW[add].tmpIPFS_Path != FWP_IPFS) {
                sc.deduct_Rep(add_OEM); 
                uint rep = sc.get_Rep(add_OEM);
                if(rep == 0) { 
                    Black_List[add_OEM] = true;
                    emit Blacklisted(manuf, add_OEM);
                }
                emit Wrong_FW_Metadata(manuf, add_OEM);
            }
            else {
                deviceFW[add].signers.push(add_OEM);
                uint count = sc.countManufNodes(manuf);
                if (deviceFW[add].signers.length > (count/2)) {
                    bytes8 dso = sc.getDSOofSD(id);
                    emit New_Firmware_Patch(add, manuf, dso, hashFWP, FWP_IPFS, v);
                }
                else {
                    emit Status(manuf, add, "Waiting for others...");
                }    
            }
        }
    }
    
    //used to issue a notification that the FW has been updated on-chain
    event FW_Updated(address indexed add, bytes8 indexed dso, bytes8 indexed manuf, bytes32 hash, uint version);
    
    //used to record the firmware hash and version after it has been updated by the device
    function recordFWupdate(uint id, address add, bytes32 hashFW, uint v) public {
        require(msg.sender == add, "Wrong device @");
        require(sc.checkID(id,add), "Mismatch of ID and @");
        require(deviceFW[add].tmphash == hashFW, "Wrong firmware metadata");
        deviceFW[add].hash = hashFW;
        deviceFW[add].version = v;
        deviceFW[add].updated = true; 
        sc.setDflag(id, false);
        delete deviceFW[add].signers;
        bytes8 manuf = sc.getOEMofSD(id);
        bytes8 dso = sc.getDSOofSD(id);
        emit FW_Updated(add, dso, manuf, hashFW, v);
    }

    //used to issue a notification requesting a check on the firmware installed
    event FW_Check(address indexed add_device, address indexed add_sender, bytes32 hashFW);

    //used to check the current firmware installed on the SI
    function RequestFWCheck(uint id, address add) public {
        require(sc.checkID(id,add), "Mismatch of ID and @");
        emit FW_Check(add, msg.sender, deviceFW[add].hash);
    }
}    
