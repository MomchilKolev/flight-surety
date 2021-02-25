// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.1 < 0.9.0;

contract FlightSurety {

    bool private operational;
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, 'Caller is not contract owner');
        _;
    }

    modifier isOperational() {
        require(operational == true, 'Contract is not operational');
        _;
    }

    function activateContract() external onlyOwner {
        operational = true;
    } 

    function deactivateContract() external onlyOwner {
        operational = false;
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

    modifier onlyRegistered() {
        require(airlines[msg.sender].exists == true, 'Caller is not a registered airline');
        _;
    }
    
    function registerAirline(string calldata name, address addr) external isOperational {
        require(airlines[msg.sender].exists == true, 'Only existing airline may register a new airline until there are at least four airlines registered');
        require(airlines[addr].exists != true, 'You are already registered');
        AirlineStatus status = AirlineStatus.PENDING_APPROVAL;
        if (airlineKeys.length < maxRegistrationsWithoutApproval) status = AirlineStatus.REGISTERED;
        address[] memory empty;
        Airline memory airline = Airline(true, name, status, empty, addr);
        airlines[addr] = airline;
        airlineKeys.push(addr);
    }
    
    function approveAirline(address airline) external onlyRegistered isOperational {
        require(!alreadyVoted(airline), 'You have already approved this airline');
        require(airlines[airline].status == AirlineStatus.PENDING_APPROVAL, 'Airline is already approved');
        airlines[airline].votes.push(msg.sender);
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
    
    function fund() external payable onlyRegistered isOperational {
        require(msg.value >= AIRLINE_REGISTRATION_FEE, 'Minimum funding is 10 ether');
        pot += msg.value;
        airlines[msg.sender].status = AirlineStatus.FUNDED;
    }
    
    function getAllAirlines() external view onlyRegistered isOperational returns (Airline[] memory) {
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

    function registerFlight(string memory flight, uint256 timestamp) external onlyRegistered isOperational {
        require(airlines[msg.sender].status == AirlineStatus.FUNDED, 'You need to submit funding of 10 ether before participating in contract');
        bytes32 key = keccak256(abi.encodePacked(msg.sender, flight, timestamp));
        Flight memory newFlight = Flight(msg.sender, flight, timestamp, key);
        flights[key] = newFlight;
        flightKeys.push(key);
    }

    function getAllFlights() external view onlyRegistered isOperational returns (Flight[] memory) {
        Flight[] memory array = new Flight[](flightKeys.length);
        for (uint i = 0; i < flightKeys.length; i++) {
            array[i] = flights[flightKeys[i]];
        }
        return array;
    }

    /*************** END: Flights ********************/
    
    /*************** BEGIN: Passengers ******************/
    
    struct Insurance {
        uint256 insuranceAmount;
        uint256 creditedAmount;
    }
    
    // Each passenger can have multiple purchased insurances
    mapping(address => mapping(bytes32 => Insurance)) insuredPassengers;
    address[] private insuredPassengerKeys;
    
    function buyInsurance(bytes32 flightKey) external payable isOperational {
        require(msg.value <= 1 ether, 'You can only insure up to 1 ether');
        pot += msg.value;
        insuredPassengers[msg.sender][flightKey] = Insurance(msg.value, 0);
        if (!hasInsurance(msg.sender)) insuredPassengerKeys.push(msg.sender);
    }
    
    function creditPassenger(address addr, bytes32 flightKey) private isOperational {
        uint256 amount = insuredPassengers[addr][flightKey].insuranceAmount;
        insuredPassengers[addr][flightKey].insuranceAmount -= amount;
        insuredPassengers[addr][flightKey].creditedAmount = amount + (amount * 50 / 100);
    }
    
    function withdraw(bytes32 flightKey) external payable isOperational {
        uint256 amount = insuredPassengers[msg.sender][flightKey].creditedAmount;
        insuredPassengers[msg.sender][flightKey].creditedAmount -= amount;
        payable(msg.sender).transfer(amount);
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
    // mapping(address => uint8[3]) oracles;

    function registerOracle() public payable isOperational {
        require(msg.value >= REGISTRATION_FEE, 'Registration fee is required');
        require(!oracles[msg.sender].exists, 'Already registered');
        uint8[3] memory indexes = generateIndexes(msg.sender);
        oracles[msg.sender] = Oracle(true, indexes);
        oracleKeys.push(msg.sender);
        emit OracleRegistration(msg.sender, indexes);
    }

    function getMyIndexes() public view isOperational returns (uint8[3] memory) {
        require(oracles[msg.sender].exists == true, 'You are not registered as an oracle');
        uint8[3] memory indexes = oracles[msg.sender].indexes;
        return indexes;
        // return oracles[msg.sender];
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
        uint256 timestamp
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
        uint8 status
    );

    function requestStatus(bytes32 key) public isOperational {
        uint8[3] memory indexes = generateIndexes(msg.sender);
        emit FlightStatus(key, indexes);
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address airline, string memory flight, uint256 timestamp) external isOperational {
        uint8 index = getRandomIndex(msg.sender);

        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        ResponseInfo storage ri = oracleResponses[key];
        ri.requester = msg.sender;
        ri.isOpen = true;

        emit OracleRequest(index, airline, flight, timestamp);
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
        uint8 statusCode
    ) external 
      isOperational
    {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );

        bytes32 key =
            keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(
            oracleResponses[key].isOpen,
            "This flight's status request is closed"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);
        
        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
        ) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            // processFlightStatus(airline, flight, timestamp, statusCode);
            oracleResponses[key].isOpen = false;
        }
    }

    /*************** END: Flight Status ************/
    
    constructor(string memory name) payable {
        // require(msg.value >= AIRLINE_REGISTRATION_FEE, 'Minimum Airline Registration fee is 10 ether');
        operational = true;
        owner = msg.sender;
        
        // address[] memory empty;
        // Airline memory airline = Airline(true, name, AirlineStatus.REGISTERED, empty, msg.sender);
        // airlines[msg.sender] = airline;
        // airlineKeys.push(msg.sender);
        
        // Flight[] memory initialFlights = new Flight[](3);
        // bytes32 key1 = keccak256(abi.encodePacked(msg.sender, 'Greenback Boogie', uint256(1612286013261)));
        // bytes32 key2 = keccak256(abi.encodePacked(msg.sender, 'Natural', uint256(1612286013900)));
        // bytes32 key3 = keccak256(abi.encodePacked(msg.sender, 'Blokira Mozuka', uint256(1612286013011)));
        // initialFlights[0] = Flight(msg.sender, 'Greenback Boogie', 1612286013261, key1);
        // initialFlights[1] = Flight(msg.sender, 'Natural', 1612286013900, key2);
        // initialFlights[2] = Flight(msg.sender, 'Blokira Mozuka', 1612286013011, key3);
        // flights[key1] = initialFlights[0];
        // flights[key2] = initialFlights[1];
        // flights[key3] = initialFlights[2];
        // flightKeys.push(key1);
        // flightKeys.push(key2);
        // flightKeys.push(key3);
    }

    /***************** BEGIN: Utility Functions *****************/

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            public
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