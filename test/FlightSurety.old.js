// // const { assert } = require("console")
// // const { isMainThread } = require("worker_threads")

// const FlightSurety = artifacts.require('./FlightSurety.sol')

// contract('FlightSurety', accounts => {
//     it('Should deploy with initial airline', async () => {
//         let instance = await FlightSurety.deployed()

//         let airlines = await instance.getAllAirlines()

//         assert.equal(airlines.length, 1, 'Deployment failed')
//     })
//     it('Only existing airline may register a new airline until there are at least four airlines registered', async () => {
//         let instance = await FlightSurety.deployed()
        
//         await instance.registerAirline('test1', accounts[1], { from: accounts[0] })
//         await instance.registerAirline('test2', accounts[2], { from: accounts[0] })
//         await instance.registerAirline('test3', accounts[3], { from: accounts[0] })
//         await instance.registerAirline('test4', accounts[4], { from: accounts[0] })

        // let airlines = await instance.getAllAirlines()
        // airlines = airlines.map(a => JSON.parse(JSON.stringify(a)))
        // let registeredAirlines = airlines.filter(a => a[2] == 1)

        // assert.equal(registeredAirlines.length, 4, 'Incorrect registration logic')
//     })
    // it('Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines', async () => {
    //     let instance = await FlightSurety.deployed()
        
    //     await instance.approveAirline(accounts[4], { from: accounts[0]})
    //     await instance.approveAirline(accounts[4], { from: accounts[1]})

    //     let airlines = await instance.getAllAirlines()
    //     let afterApproval = airlines[4]

    //     assert.equal(afterApproval[2], 1, 'Approval was unsuccessfurebol')
    // })
    // it('Initial flights on deploy', async () => {
    //     let instance = await FlightSurety.deployed()

    //     let flights = await instance.getAllFlights()

    //     assert.equal(flights.length, 3, 'Incorrect number of initial flights')
    // }),
    // it('Airline can be registered, but does not participate in contract until it submits funding of 10 ether', async () => {
    //     let instance = await FlightSurety.deployed()

    //     await instance.registerAirline('NOT FUNDING!', accounts[5], { from: accounts[0] })
    //     try {
    //         await instance.registerFlight('Lebron', Date.now())
    //     } catch (err) {
    //         assert.equal(err.reason, 'You need to submit funding of 10 ether before participating in contract', 'Incorrect require error message')
    //     }
    // })
// })