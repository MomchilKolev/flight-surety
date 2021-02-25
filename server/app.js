const Web3 = require('web3')
const fastify = require('fastify')({
    logger: true
})

const FlightSuretyApp = require('../client/src/contracts/FlightSuretyApp.json')
const FlightSuretyData = require('../client/src/contracts/FlightSuretyData.json')
const { localhost: config } = require('./config.json')

let web3 = new Web3(config.url);
web3.eth.defaultAccount = web3.eth.accounts[0]
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress)
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress)

let numOfOracles = 50
let oracles = {}
const STATUS_CODES = {
    STATUS_CODE_UNKNOWN: 0,
    STATUS_CODE_ON_TIME: 10,
    STATUS_CODE_LATE_AIRLINE: 20,
    STATUS_CODE_LATE_WEATHER: 30,
    STATUS_CODE_LATE_TECHNICAL: 40,
    STATUS_CODE_LATE_OTHER: 50,
}

// flightSuretyData.events.OracleRegistration({}, () => {})
flightSuretyApp.events.OracleRegistration({}, () => {})
.on('data', data => {
    console.log('Oracle Registration event received with data', data)
    const { returnValues } = data
    oracles[returnValues.addr] = returnValues.indexes;
})

flightSuretyData.events.OracleRequest().on('data', async data => {
    console.log('Oracle flight status request received')
    const { returnValues } = data
    const { index, airline, flight, timestamp, flightKey } = returnValues
    for (let oracle in oracles) {
        if (oracles[oracle].includes(index)) {
            try {
                await flightSuretyApp.methods.submitOracleResponse(index, airline, flight, timestamp, randomStatus(STATUS_CODES), flightKey).send({ from: oracle, gas: 1999999 })
            } catch (err) {
                const { reason } = err.data[Object.keys(err.data)[0]]
                console.log('reason is', reason)
                console.log('err is', err)
            }
        }
    }
})

flightSuretyData.events.FlightStatusInfo().on('data', data => {
    const { returnValues } = data
    console.log('FlightStatusInfo', returnValues)
})

web3.eth.getAccounts().then(async accs => {
    console.log('accs', accs)
    let oracleAccounts = accs.slice(10, 20 + numOfOracles);
    
    oracleAccounts.forEach(async acc => {
        await flightSuretyApp.methods.registerOracle().send({ from: acc, gas: 1999999, value: 1000000000000000000 })
    }, {})

    // simulate FE flight status request
    // const flights = await flightSuretyApp.methods.getAllFlights().call({from: config.firstAirline})
    // const [airline, flight, timestamp, key] = flights[0]
    // await flightSuretyApp.methods.fetchFlightStatus(airline, flight, timestamp).send({ from: config.firstAirline }); 
    // console.log('after', flights)
})

function randomStatus(statusCodes) {
    let keys = Object.keys(statusCodes)
    let statusCodeIndex = Math.floor(Math.random() * keys.length)
    return statusCodes[keys[statusCodeIndex]]
}