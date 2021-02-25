var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);

    // Authorize AppContract on DataContract
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);

    // Register First Airline
    await config.flightSuretyApp.registerAirline('Wright Brothers', config.firstAirline, { from: config.firstAirline });

    // Fund First Airline
    await config.flightSuretyApp.fund({ from: config.firstAirline, value: 10000000000000000000 })

    // Register First 3 flights
    await config.flightSuretyApp.registerFlight('Flyer 1', Math.floor(Date.now() + 100000000 * Math.random()), {from: config.firstAirline});
    await config.flightSuretyApp.registerFlight('Flyer 2', Math.floor(Date.now() + 100000000 * Math.random()), {from: config.firstAirline});
    await config.flightSuretyApp.registerFlight('Flyer 3', Math.floor(Date.now() + 100000000 * Math.random()), {from: config.firstAirline});
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSuretyData.registerAirline(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  
  it('Should deploy with initial airline', async () => {
      let airlines = await config.flightSuretyApp.getAllAirlines({from: config.firstAirline})
      assert.equal(airlines.length, 1, 'Deployment Failed')
    })
    
    
    it('Only existing airline may register a new airline until there are at least four airlines registered', async () => {
        await config.flightSuretyApp.registerAirline('test2', config.testAddresses[2], { from: config.firstAirline })
        await config.flightSuretyApp.registerAirline('test3', config.testAddresses[3], { from: config.firstAirline })
        await config.flightSuretyApp.registerAirline('test4', config.testAddresses[4], { from: config.firstAirline })
        await config.flightSuretyApp.registerAirline('test5', config.testAddresses[5], { from: config.firstAirline })
        
        let airlines = await config.flightSuretyApp.getAllAirlines()
        airlines = airlines.map(a => JSON.parse(JSON.stringify(a)))
        let registeredAirlines = airlines.filter(a => a[2] > 0)
        
        assert.equal(registeredAirlines.length, 4, 'Incorrect registration logic')
    })
    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
        
        // ARRANGE
        let newAirline = config.testAddresses[2];
    
        // ACT
        try {
            await config.flightSuretyApp.registerAirline('Name', config.testAddresses[7], {from: newAirline});
        }
        catch (err) {        
            // ASSERT
            assert.equal(err.reason, '(airline) cannot register an Airline using registerAirline() if it is not funded', "Airline should not be able to register another airline if it hasn't provided funding");
            return
        }
        assert.equal(true, false, 'Something went wrong')
    
    });
    it('Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines', async () => {
        await config.flightSuretyApp.approveAirline(config.testAddresses[5], { from: config.firstAirline })
        await config.flightSuretyApp.approveAirline(config.testAddresses[5], { from: config.testAddresses[2] })

        let airlines = await config.flightSuretyApp.getAllAirlines()
        let afterApproval = airlines[4]

        assert.equal(afterApproval[2], 1, 'Approval was unsuccessful')
    })
    it('Initial flights on deploy', async () => {
        let flights = await config.flightSuretyApp.getAllFlights({ from: config.firstAirline })
        assert.equal(flights.length, 3, 'Incorrect number of initial flights')
    }),
    it('Airline can be registered, but does not participate in contract until it submits funding of 10 ether', async () => {
        await config.flightSuretyApp.registerAirline('NOT FUNDING!', config.testAddresses[6], { from: config.firstAirline })
        try {
            await config.flightSuretyApp.registerFlight('Lebron', Date.now(), {from: config.testAddresses[6]})
        } catch (err) {
            assert.equal(err.reason, 'You need to submit funding of 10 ether before participating in contract', 'Incorrect require error message')
        }
    })
});