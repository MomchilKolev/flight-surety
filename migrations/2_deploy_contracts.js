const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = function(deployer, network, accounts) {

    let firstAirline = accounts[1];
    deployer.deploy(FlightSuretyData)
    .then(() => {
        return deployer.deploy(FlightSuretyApp, FlightSuretyData.address)
                .then(async () => {
                    let config = {
                        localhost: {
                            url: 'ws://localhost:7545',
                            dataAddress: FlightSuretyData.address,
                            appAddress: FlightSuretyApp.address,
                            firstAirline
                        }
                    }
                    fs.writeFileSync(__dirname + '/../client/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
                    fs.writeFileSync(__dirname + '/../server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');

                    let dataInstance = await FlightSuretyData.deployed();
                    let appInstance = await FlightSuretyApp.deployed();

                    // Authorize AppContract on DataContract
                    await dataInstance.authorizeCaller(FlightSuretyApp.address, { from: accounts[0]  });
                    // Register First Airline
                    await appInstance.registerAirline('Wright Brothers', firstAirline, { from: firstAirline });
                    // Fund First Airline
                    await appInstance.fund({ from: firstAirline, value: 10000000000000000000})

                    // Register First 3 flights
                    await appInstance.registerFlight('Flyer 1', Math.floor(Date.now() + 100000000 * Math.random()), {from: firstAirline});
                    await appInstance.registerFlight('Flyer 2', Math.floor(Date.now() + 100000000 * Math.random()), {from: firstAirline});
                    await appInstance.registerFlight('Flyer 3', Math.floor(Date.now() + 100000000 * Math.random()), {from: firstAirline});
                });
    });
}