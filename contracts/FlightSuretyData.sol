// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.1 < 0.9.0;

contract FlightSuretyData {

    bool private operational;
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, 'Caller is not contract owner');
        _;
    }

    modifier isOperating() {
        require(operational == true, 'Contract is not operational');
        _;
    }

    function isOperational() external view returns (bool) {
        return operational;
    }

    function setOperatingStatus(bool status) external onlyOwner {
        operational = status;
    }

    function activateContract() external onlyOwner {
        operational = true;
    } 

    function deactivateContract() external onlyOwner {
        operational = false;
    }

    // Authorization
    mapping(address => bool) authorizedContracts;

    function authorizeCaller(address addr) external onlyOwner {
        authorizedContracts[addr] = true;
    }

    function deauthorizeCaller(address addr) external onlyOwner {
        authorizedContracts[addr] = false;
    }

    modifier isAuthorized() {
        require(authorizedContracts[msg.sender] == true, 'Caller is not authorized');
        _;
    }
    
    /*************** BEGIN: Airlines ****************/
    
    enum AirlineStatus { PENDING_APPROVAL, REGISTERED, FUNDED }
    
    struct Airline {
        bool exists;
        string name;
        AirlineStatus status;
        address[] votes;
        address addr;
    }
    
    mapping(address => Airline) airlines;
    address[] airlineKeys;
    uint8 maxRegistrationsWithoutApproval = 4;
    uint256 AIRLINE_REGISTRATION_FEE = 10 ether;
    uint256 pot;

    modifier onlyRegistered(address from) {
        require(airlines[from].exists == true, 'Caller is not a registered airline');
        _;
    }
    
    function registerAirline(address from, string calldata name, address addr) external isOperating isAuthorized {
        require(airlines[from].exists == true || airlineKeys.length == 0, 'Only existing airline may register a new airline until there are at least four airlines registered');
        require(airlines[addr].exists != true, 'You are already registered');
        require(airlines[from].status == AirlineStatus.FUNDED || airlineKeys.length == 0, '(airline) cannot register an Airline using registerAirline() if it is not funded');
        AirlineStatus status = AirlineStatus.PENDING_APPROVAL;
        if (airlineKeys.length < maxRegistrationsWithoutApproval) status = AirlineStatus.REGISTERED;
        address[] memory empty;
        Airline memory airline = Airline(true, name, status, empty, addr);
        airlines[addr] = airline;
        airlineKeys.push(addr);
    }
    
    function approveAirline(address from, address airline) external onlyRegistered(from) isOperating isAuthorized {
        require(!alreadyVoted(airline), 'You have already approved this airline');
        require(airlines[airline].status == AirlineStatus.PENDING_APPROVAL, 'Airline is already approved');
        airlines[airline].votes.push(from);
        if (airlines[airline].votes.length >= airlineKeys.length / 2 && airlines[airline].status != AirlineStatus.REGISTERED) {
            airlines[airline].status = AirlineStatus.REGISTERED;
            address[] memory empty;
            airlines[airline].votes = empty;
        }
    }
    
    function alreadyVoted(address airline) private view returns (bool) {
        for (uint i = 0; i < airlines[airline].votes.length; i++) {
            if (airlines[airline].votes[i] == msg.sender) return true;
        }
        return false;
    }
    
    function fund(address from) external payable onlyRegistered(from) isOperating isAuthorized {
        require(msg.value >= AIRLINE_REGISTRATION_FEE, 'Minimum funding is 10 ether');
        pot += msg.value;
        airlines[from].status = AirlineStatus.FUNDED;
    }
    
    function getAllAirlines() external view isOperating isAuthorized returns (Airline[] memory) {
        Airline[] memory array = new Airline[](airlineKeys.length);
        for (uint i = 0; i < airlineKeys.length; i++) {
            array[i] = airlines[airlineKeys[i]];
        }
        return array;
    }
    
    /*************** END: Airlines *******************/
    
    /*************** BEGIN: Flights ******************/
    
    struct Flight {
        address airline;
        string flight;
        uint256 timestamp;
        bytes32 key;
    }
    
    mapping(bytes32 => Flight) flights;
    bytes32[] flightKeys;

    function registerFlight(address from, string memory flight, uint256 timestamp) external onlyRegistered(from) isOperating isAuthorized {
        // require(airlines[msg.sender].status == AirlineStatus.FUNDED, 'You need to submit funding of 10 ether before participating in contract');
        bytes32 key = keccak256(abi.encodePacked(msg.sender, flight, timestamp));
        Flight memory newFlight = Flight(msg.sender, flight, timestamp, key);
        flights[key] = newFlight;
        flightKeys.push(key);
    }

    function getAllFlights() external view isOperating isAuthorized returns (Flight[] memory) {
        Flight[] memory array = new Flight[](flightKeys.length);
        for (uint i = 0; i < flightKeys.length; i++) {
            array[i] = flights[flightKeys[i]];
        }
        return array;
    }

    /*************** END: Flights ********************/
    
    /*************** BEGIN: Passengers ******************/

    struct Insurance {
        uint insuranceAmount;
        uint creditedAmount;
    }
    
    mapping(address => mapping(bytes32 => uint)) insuredPassengers;
    mapping(address => uint) passengerCredit;
    address[] private insuredPassengerKeys;
    
    function buyInsurance(address from, bytes32 flightKey) external payable isOperating isAuthorized {
        // require(msg.value <= 1 ether && insuredPassengers[from][flightKey] + msg.value <= 1 ether, 'You can only insure up to 1 ether');
        pot += msg.value;
        insuredPassengers[from][flightKey] = msg.value;
        passengerCredit[from] = 0;
        if (!hasInsurance(from)) insuredPassengerKeys.push(from);
    }

    function getInsurance(address from, bytes32 flightKey) public view isAuthorized returns (Insurance memory) {
        return Insurance(insuredPassengers[from][flightKey], passengerCredit[from]);
    }

    function getCredit(address from) public view isAuthorized returns (uint) {
        return passengerCredit[from];
    }
    
    function creditPassenger(address addr, bytes32 flightKey) private isOperating {
        require(insuredPassengers[addr][flightKey] > 0, 'You are not insured');
        uint256 amount = insuredPassengers[addr][flightKey];
        insuredPassengers[addr][flightKey] -= amount;
        passengerCredit[addr] = amount + (amount * 50 / 100);
        // passengerCredit[addr] = amount;
    }
    
    function withdraw(address payable from) external payable isOperating isAuthorized {
        uint256 amount = passengerCredit[from];
        passengerCredit[from] -= amount;
        pot -= amount;
        payable(from).transfer(amount);
    }

    function hasInsurance(address addr) private view returns (bool) {
        for (uint i = 0; i < insuredPassengerKeys.length; i++) {
            if (insuredPassengerKeys[i] == addr) return true;
        }
        return false;
    }
    
    /*************** END: Passengers ******************/

    /*************** BEGIN: Oracles ****************/

    uint256 REGISTRATION_FEE = 1 ether;
    uint256 nonce = 0;

    event OracleRegistration(address addr, uint8[3] indexes);

    struct Oracle {
        bool exists;
        uint8[3] indexes;
    }
    mapping(address => Oracle) oracles;
    address[] oracleKeys;

    function registerOracle(address from) public payable isOperating isAuthorized {
        require(msg.value >= REGISTRATION_FEE, 'Registration fee is required');
        require(!oracles[from].exists, 'Already registered');
        uint8[3] memory indexes = generateIndexes(from);
        oracles[from] = Oracle(true, indexes);
        oracleKeys.push(from);
        emit OracleRegistration(from, indexes);
    }

    function getMyIndexes(address from) public view isOperating isAuthorized returns (uint8[3] memory) {
        require(oracles[from].exists == true, 'You are not registered as an oracle');
        uint8[3] memory indexes = oracles[from].indexes;
        return indexes;
    }

    /*************** END: Oracles ******************/

    /*************** BEGIN: Flight Status **********/

    // Flight status codes
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
                                                        // submit
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    event FlightStatus(bytes32 key, uint8[3] indexes);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp,
        bytes32 flightKey
    );

    event OracleReport(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status,
        bytes32 flightKey
    );

    function requestStatus(address from, bytes32 key) public isOperating isAuthorized {
        uint8[3] memory indexes = generateIndexes(from);
        emit FlightStatus(key, indexes);
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address from, address airline, string memory flight, uint256 timestamp, bytes32 flightKey) external isOperating isAuthorized {
        uint8 index = getRandomIndex(from);

        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        ResponseInfo storage ri = oracleResponses[key];
        ri.requester = from;
        ri.isOpen = true;

        emit OracleRequest(index, airline, flight, timestamp, flightKey);
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        address from, 
        uint8 index,
        address airline,
        string calldata flight,
        uint256 timestamp,
        uint8 statusCode,
        bytes32 flightKey
    ) external 
      isOperating
      isAuthorized
    {
        // require(
        //     (oracles[from].indexes[0] == index) ||
        //         (oracles[from].indexes[1] == index) ||
        //         (oracles[from].indexes[2] == index),
        //     "Index does not match oracle request"
        // );

        bytes32 key =
            keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(
            oracleResponses[key].isOpen,
            "This flight's status request is closed"
        );

        oracleResponses[key].responses[statusCode].push(from);
        
        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        // emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES && oracleResponses[key].isOpen == true
        ) {
            oracleResponses[key].isOpen = false;
            // credit every customer purchased insurance for this flight
            // Handle flight status as appropriate
            // processFlightStatus(airline, flight, timestamp, statusCode);

            if (statusCode == STATUS_CODE_LATE_AIRLINE) {
                for (uint i = 0; i < insuredPassengerKeys.length; i++) {
                    if (insuredPassengers[insuredPassengerKeys[i]][flightKey] > 0) {
                        creditPassenger(insuredPassengerKeys[i], flightKey);
                    }
                }
            }

            emit FlightStatusInfo(airline, flight, timestamp, statusCode, flightKey);

        }
    }

    /*************** END: Flight Status ************/
    
    constructor() payable {
        operational = true;
        owner = msg.sender;
        pot += msg.value;
    }

    /***************** BEGIN: Utility Functions *****************/

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            public
                            isOperating
                            isAuthorized
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            isOperating
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp + nonce++, account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    /***************** END: Utility Functions *******************/
}