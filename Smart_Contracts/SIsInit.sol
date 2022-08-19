// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
 
contract SIsInit {

    //**********************************************************Data Structures & Modifiers*********************************************************************
    
    //structure defining the distributed energy resources (DERs) management system's entities part of the blockchain framework
    struct DERMS {
        bytes8 name; //the name of distribution system operator (DSO) managing the fleet of DERs
        address[] add_DERAN; //address of all aggregator nodes (AN) managed by a certain DSO
    }
    
    //structure defining the original equipment manufacturers (OEMs) part of the blockchain framework
    struct Manufacturer {
        bytes8 name; //the name of the OEM of the smart inverter devices part of the framework.
        address[] add_OEMN; //addresses of all OEM nodes managed by a certain manufacturer
        uint256[] D_Serials; //list of unique serial numbers of the devices managed by a certain manufacturer, used during the implementation of the access control
    }

    //structure defining the meta data of the devices
    struct Device {
        address add; //address of the smart device 
        uint types; //to indicate the type of the device, in this implementation the type is either a SI(=1) or a SM(=2), but could be extended with more
        bytes8 OEM; //the original equipment manufacturer of the device
        bytes8 DSO; //the operator managing the grid zone under which the device is connected
        uint256 serial_num; //unique serial number of the device
        bool red_flag; //set as true if firmware of the device is not up to date
    }
    
    DERMS[] public operators; //array used to store the data of the DSOs part of the consortium blockchain
    
    Manufacturer[] public manufacturers; //array used to store the data of the OEMs part of the consortium blockchain
    
    Device[] public Devices; //array used to store the data of the smart inverters (SIs)
    
    address[] public admins; //addresses of administrators (i.e., TSO) used to execute some functions during the initialization phase
    
    mapping(address => uint) public OEMN_Reputation; //mapping of all manufacturer nodes and their reputation score

    address add_scFW; //address of firmware smart contract

    //used to restrict the execution of a function only by the admins' nodes using their blockchain addresses
    modifier onlyByAdmin() {
        uint tmp = 0;
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                tmp = 1;
                break;
            }
        }
        require(tmp != 0, 'Not an admin!');
        _;
    }
    
    //used to restrict the execution of a function only to the DERANs
    modifier onlyByDERMS(bytes8 op, address add) {
        uint tmp = 0;
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i].name == op) {
                for (uint j = 0; j < operators[i].add_DERAN.length; j++) {
                    if (operators[i].add_DERAN[j] == add) {
                        tmp = 1;
                        break;
                    }
                }
                break;
            }
        }
        if (tmp == 0)
        revert('Not a DER aggregator!');
        _; 
    }
    
    //used to restrict the execution of a function only to the OEMNs
    modifier onlyByManuf(bytes8 manuf, address add) {
        uint tmp1 = 0;
        uint tmp2 = 0;
        for (uint i = 0; i < manufacturers.length; i++) {
            if (manufacturers[i].name == manuf) {
                tmp1 =1;
                for (uint j = 0; j < manufacturers[i].add_OEMN.length; j++) {
                    if (manufacturers[i].add_OEMN[j] == add) {
                        tmp2 = 1;
                        break;
                    }
                }
                break;
            }
        }
        if (tmp1 == 0)
        revert('OEM not registered!');
        _;
        if (tmp2 == 0) 
        revert('Unauthorized access!');
        _;
    }
    
    
    //used to restrict the execution of a function to the SI
    modifier onlyDevice(uint id, address add) {
        if (Devices[id].add != add)
        revert('Mismatch of input data!');
        _; 
    }

    //used to secure the external calls from the firmware contact to the initialization contract
    modifier onlybyscFW () {
        require(msg.sender == add_scFW, 'Unauthorized call');
        _;
    }
    
    //verifies if the provided serial number of the device matches with the OEM, used to bind the device with the OEM for access control
    modifier verifyOEM(bytes8 m, uint256 s) {
        uint tmp = 0;
        for (uint i = 0; i < manufacturers.length; i++) {
            if (manufacturers[i].name == m) {
                for (uint j = 0; j < manufacturers[i].D_Serials.length; j++) {
                    if (manufacturers[i].D_Serials[j] == s) {
                        tmp = 1;
                        break;
                    }
                }
                break;
            }
        }
        if (tmp == 0)
        revert('Mismatch of serial and OEM!');
        _; 
    }
    
    //****************************************************Smart Contract Constructor, Functions & Events*****************************************************************

    //constructor of the smart contract, initializes the array for the admins' addresses 
    //with the address of the msg sender that deployed the contract to the blockchain network
    constructor() {
        admins.push(msg.sender);
    }
    
    // triggered upon adding a new admin node
    event Admin_added(address indexed admin);

    //adds more admin nodes to avoid having a single one (which is not recommended for obvious security reasons)
    function addAdmin(address add) public onlyByAdmin() {
            admins.push(add); 
            emit Admin_added(add); 
    }
    
    //triggered upon adding a DSO
    event DERA_added(bytes8 indexed dso);

    //adds aggregators to the blockchain framework   
    function DERAInit(bytes8 OperatorName) public onlyByAdmin() {
        operators.push(DERMS({
            name: OperatorName,
            add_DERAN: new address[](0)
            }));
        emit DERA_added(OperatorName);    
    }
    
    //triggered upon adding an OEM
    event OEM_added(bytes8 indexed manuf);

    //adds manufacturers to the blockchain framework 
    function OEMInit(bytes8 ManufName) public onlyByAdmin() {
        manufacturers.push(Manufacturer({
            name: ManufName,
            add_OEMN: new address[](0),
            D_Serials: new uint256[](0)
            }));
        emit OEM_added(ManufName);    
    }

    //triggered upon adding the addresses of the DERA
    event DERAN_added(bytes8 indexed dso, address indexed node);

    //adds list of aggregators' addresses for each DERMS
    function DERANUpdate(bytes8 name, address add) public onlyByAdmin() {
        uint tmp = 0;
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i].name == name) {
                tmp = 1;
                operators[i].add_DERAN.push(add);  
                break;     
            }
        }
        if (tmp == 0) {
            revert('DERA not registered!');
        }
        emit DERAN_added(name, add);
    }

    //triggered upon adding the OEMs nodes addresses
    event OEMN_added(bytes8 indexed manuf, address indexed node);

    //adds list of addresses for each manufacturer
    function OEMNUpdate(bytes8 name, address add) public onlyByAdmin() {
        uint tmp = 0;
        for (uint i = 0; i < manufacturers.length; i++) {
            if (manufacturers[i].name == name) {
                tmp = 1;
                manufacturers[i].add_OEMN.push(add);
                OEMN_Reputation[add] = 5;  
                break;    
            }
        }
        if (tmp == 0) {
            revert('OEM not registered!');
        }
        emit OEMN_added(name, add);
    }

    //triggered when the serial numbers of the devices are recorded on the blockchain
    event SerialNum_added(bytes8 indexed OEM, uint256 indexed s);

    //adds list of devices' serials for each manufacturer
    function OEMSUpdate(bytes8 OEM_name, uint256 serial) public onlyByManuf(OEM_name, msg.sender) {
        for (uint i = 0; i < manufacturers.length; i++) {
            if (manufacturers[i].name == OEM_name) {
                manufacturers[i].D_Serials.push(serial);
                break;    
            }
        }
        emit SerialNum_added(OEM_name, serial);
    }
 
    //triggered when a device data is recorded on the blockchain, returns the device unique ID
    event Device_added(uint ID, bytes8 indexed DERA, bytes8 indexed OEM, address indexed add);

    //adds devices only by the DERMS aggregators nodes
    function addDevice(address d_add, bytes8 d_OEM, bytes8 d_DSO, uint256 d_serial, uint d_type) public onlyByDERMS(d_DSO, msg.sender) verifyOEM(d_OEM, d_serial) {
        Devices.push(Device({
                add: d_add,
                types: d_type, 
                OEM: d_OEM,
                DSO: d_DSO,
                serial_num: d_serial,
                red_flag: false
            }));
        emit Device_added(Devices.length-1, d_DSO, d_OEM, d_add);        
    }

    //*********************************************************External Call Functions*******************************************************************************************
    
    //sets the address of PVsFM SC
    function set_addscFW (address add) public onlyByAdmin(){
        add_scFW = add;
    }

    //external call restricted to SIsFirmware SC used to reduce the reputation of the OEMN upon uploading false meta data
    function deduct_Rep (address add) public onlybyscFW (){
        OEMN_Reputation[add]--;
    }

    //changes the reputation score in case of miscalculated hash, only by the admin nodes
    function change_Rep(address add, uint Repcase) public onlyByAdmin(){
        if (Repcase == 1) {
        OEMN_Reputation[add]++;
        }
        if (Repcase == 2) {
        OEMN_Reputation[add]--;
        }
    }
    
    //returns reputation of an OEMN
    function get_Rep (address add) public view returns (uint){
        return(OEMN_Reputation[add]);
    }

    //returns the number of nodes registered per each OEM, used with the firmware update signers' array
    function countManufNodes(bytes8 manuf) public view returns (uint) {
        uint u = 0;    
        for (uint i = 0; i < manufacturers.length; i++) {
            if (manufacturers[i].name == manuf) {
                u = manufacturers[i].add_OEMN.length;
                break;
            }
        }
        return u;
    }

    //returns the name of the OEM using the ID of a device
    function getOEMofSD(uint id) public view returns (bytes8) {
        return Devices[id].OEM;
    }

    //returns the name of the DSO using the ID of a device
    function getDSOofSD(uint id) public view returns (bytes8) {
        return Devices[id].DSO;
    }

    //changes the value of the red flag of each device (true or false), only by the firmware smart contract and it's executed automatically
    function setDflag(uint id, bool flag) public onlybyscFW () {
        Devices[id].red_flag = flag;
    }

    //queries the red flag value of the device 
    function getDflag(uint id) public view returns (bool) {
        return Devices[id].red_flag;
    }

    //queries the type of the device (SM or SI)
    function getDType(address add_d) public view returns (uint) {
        uint type_d;
        for (uint i = 0; i < Devices.length; i++){
            if (Devices[i].add == add_d) {
            type_d = Devices[i].types;
            break;
            }   
        }
        return type_d;
    }

    //verifies association between device and OEM 
    function checkManuf(bytes8 manuf, address add) public view onlyByManuf(manuf, add) returns (bool) {
        return true;
    }

    //verifies association between device and DSO 
    function checkDSO(bytes8 op, address add) public view onlyByDERMS(op, add) returns (bool) {
        return true;
    }

    //verifies association between ID of device and its address
    function checkID(uint id, address add) public view onlyDevice(id, add) returns (bool) {
        return true;
    }
}    
