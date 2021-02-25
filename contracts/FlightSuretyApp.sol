// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.1 < 0.9.0;

contract FlightSuretyApp {

    /*************** BEGIN: Oracle State ********************/
    uint256 REGISTRATION_FEE = 1 ether;
    uint256 nonce = 0;

    event OracleRegistration(address addr, uint8[3] indexes);

    struct Oracle {
        bool exists;
        uint8[3] indexes;
    }
    mapping(address => Oracle) oracles;
    address[] oracleKeys;
    /*************** END: Oracle State ********************/

    FlightSuretyInterface dataContract;

    constructor(address dataContractAddress) {
        dataContract = FlightSuretyInterface(dataContractAddress);
    }
    
    function registerAirline(string calldata name, address addr) external {
        dataContract.registerAirline(msg.sender, name, addr);
    }
    
    function approveAirline(address airline) external {
        dataContract.approveAirline(msg.sender, airline);
    }

    function fund() external payable {
        dataContract.fund{value: msg.value}(msg.sender);
    }
    
    function getAllAirlines() external view returns (FlightSuretyInterface.Airline[] memory) {
        return dataContract.getAllAirlines();
    }

    /*************** BEGIN: Flights ******************/

    function registerFlight(string memory flight, uint256 timestamp) external {
        dataContract.registerFlight(msg.sender, flight, timestamp);
    }

    function getAllFlights() external view returns (FlightSuretyInterface.Flight[] memory) {
        return dataContract.getAllFlights();
    }

    /*************** END: Flights ********************/

    /*************** BEGIN: Passengers ******************/
    
    function buyInsurance(bytes32 flightKey) external payable {
        dataContract.buyInsurance{value: msg.value}(msg.sender, flightKey);
    }

    function getInsurance(bytes32 flightKey) public view returns (FlightSuretyInterface.Insurance memory) {
        return dataContract.getInsurance(msg.sender, flightKey);
    }

    function getCredit() public view returns (uint) {
        return dataContract.getCredit(msg.sender);
    }

    function withdraw() external payable {
        dataContract.withdraw{value: msg.value}(payable(msg.sender));
    }
    
    /*************** END: Passengers ******************/

    /*************** BEGIN: Oracles ****************/

    function registerOracle() public payable {
        // dataContract.registerOracle{value: msg.value}(msg.sender);
        require(msg.value >= REGISTRATION_FEE, 'Registration fee is required');
        require(!oracles[msg.sender].exists, 'Already registered');
        uint8[3] memory indexes = dataContract.generateIndexes(msg.sender);
        oracles[msg.sender] = Oracle(true, indexes);
        oracleKeys.push(msg.sender);
        emit OracleRegistration(msg.sender, indexes);
    }

    function getMyIndexes() public view returns (uint8[3] memory) {
        // return dataContract.getMyIndexes(msg.sender);
        require(oracles[msg.sender].exists == true, 'You are not registered as an oracle');
        uint8[3] memory indexes = oracles[msg.sender].indexes;
        return indexes;
    }

    /*************** END: Oracles ******************/

    /*************** BEGIN: Flight Status **********/

    function requestStatus(bytes32 key) public {
        dataContract.requestStatus(msg.sender, key);
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address airline, string memory flight, uint256 timestamp, bytes32 key) public {
        dataContract.fetchFlightStatus(msg.sender, airline, flight, timestamp, key);
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string calldata flight,
        uint256 timestamp,
        uint8 statusCode,
        bytes32 flightKey
    ) public 
      
    {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );
        dataContract.submitOracleResponse(msg.sender, index, airline, flight, timestamp, statusCode, flightKey);
    }

    /*************** END: Flight Status ************/
}

interface FlightSuretyInterface {

    // Airline Data Structures
    enum AirlineStatus { PENDING_APPROVAL, REGISTERED, FUNDED }

    struct Airline {
        bool exists;
        string name;
        AirlineStatus status;
        address[] votes;
        address addr;
    }

    // Flight Data Structures
    struct Flight {
        address airline;
        string flight;
        uint256 timestamp;
        bytes32 key;
    }

    // Passenger Data Structures
    struct Insurance {
        uint256 insuranceAmount;
        uint256 creditedAmount;
    }

    // Oracle Data Structures
    struct Oracle {
        bool exists;
        uint8[3] indexes;
    }
    
    // Airline functions
    function registerAirline(address from, string calldata name, address addr) external;
    function approveAirline(address from, address airline) external;
    function fund(address from) external payable;
    function getAllAirlines() external view returns (Airline[] memory);

    // Flight functions
    function registerFlight(address from, string memory flight, uint256 timestamp) external;
    function getAllFlights() external view returns (FlightSuretyInterface.Flight[] memory);

    // Passenger functions
    function buyInsurance(address from, bytes32 flightKey) external payable;
    function getInsurance(address from, bytes32 flightKey) external view returns (Insurance memory);
    function getCredit(address from) external view returns (uint);
    function withdraw(address payable from) external payable;

    // Oracle functions
    function registerOracle(address from) external payable;
    function getMyIndexes(address from) external view returns (uint8[3] memory);
    function generateIndexes(address account) external returns(uint8[3] memory);

    // Flight Status functions
    function requestStatus(address from, bytes32 key) external;
    function fetchFlightStatus(address from, address airline, string memory flight, uint256 timestamp, bytes32 key) external;
    function submitOracleResponse(
        address from,
        uint8 index,
        address airline,
        string calldata flight,
        uint256 timestamp,
        uint8 statusCode,
        bytes32 flightKey
    ) external;
}