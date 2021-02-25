
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        '0x60CCe9a47Da4e9eE717559726A91279337B92fC9',
        '0x82E918728339E8d7eCD2196918506e912f78ecB8',
        '0x2C986b363Df9e56f394eC64627AdA7847d674e11',
        '0xba89c66c0D3c0F8b5EFCDa2bcdE5e50B9c854Aff',
        '0xaFEAaCaE6EEE514c84870DF95353d413bA83FfaF',
        '0x3B1dB255b28F511652981E4c2502DE018098036e',
        '0xEe9cEeD7BC46Be479F8B73129d00F278320e95bf',
        '0xFE236C752F1feDE7295Ac6F489010778E39f9BC3',
        '0x70952E9694eAAa55Ea1397f0AC0409Fb8e80AdBF',
        '0x32a162d361787c44643c3E03344be6204AA4Ff5B',
        '0x550DA6aA36e8795741fc3C3cb96A251B4F1Ee346',
        '0xd8A436B13405417bd6eFe09a3d343f7141eCAbc8',
        '0x5A2486c5064fa35419f5DdB5138Ca4165c5D94de',
        '0x3CBCB23a73F72a8C9eFEC22d589bC936B620efa3',
        '0x2FF79C7294aBEb7B0606C578c1dEda83451510F6',
        '0xCCf6A4ec1ea5643447c725FCA61422d0AE44d9Dd',
        '0x2B1ddC5448D37512200aB65CB7b0b0bCA6B91313',
        '0x40C60C8DbB9d31A1d64aC52159dA55CE2A43D59A',
        '0xC68A784182A48836aD4d1D10e23931244ea02B5d',
        '0x721a6c6f0a3d903840a7AB9D8c78F6bbE108fE02',
        '0x0E8618986fAba8288489Adb3aDf6575324eFcB1a',
        '0xeCC70f9feba60879B9405dB3153dE116a25A40Ef',
        '0x1d62fC992c39313A77B117a6e25fFEb675863f06',
        '0xa664ed39d966f0762179F7166bB72eB4B8dFe065',
        '0xbcA1CBb9E380F81eCeade678F8Fd73F17c549226',
        '0x2DB434bED2dfCE780752eC8ac4529f3cc131E381',
        '0xce41aF70ecbfC1a4F6CDc29866D7a59bf125F2F9',
        '0xcA3C9706Ea725946D7FD5E7eDac38b2Da8cA107b',
        '0xc610573E1cf5E8691845282642B8657FBcBDE59b',
        '0xa8D5D65680e2439b6fb35a3d08c2a70176C5FfFE',
        '0x3cF73de94Ce49243FEcF2a1f1a8B07D0Fb1d711c',
        '0xdde14F5D2197D144363a5fB75eaA63ED353a8B05',
        '0x245d8d115216C627ac51A35a531a6d76Dcf4E00B',
        '0x2467BD9B2A90574C8EA8502418Ba6A5cB077eF04',
        '0x0b2d26Db30E96c2b0c9EA25c6a0Dce94123fc82d',
        '0x8d4B74D344eB42e0fc6bDF390bb4500faBb6cA12',
        '0xB39BA2E18446509ACb77b8ea19bB1694e0506561',
        '0x83146E2c972E8f85590939b3Afbbabe883AC16bf',
        '0xCa290B5b4e6fa87AC806d7624770516055815831',
        '0x3377Ef74F4fbCdce655D35a62182F9d305f29512',
        '0x2Ecb7f513FF17E1A0313D68919224ed921916AC8',
        '0x88A3d37D95056424C4446FFEB408a97d3109219e',
        '0x00A3f397bDE06EB0DD5Ff1BFcC5d2c672D702079',
        '0x757d5f923c50482d0ce6A62a8D78adbDe43Ca3D3',
        '0xeD35f4208395d432BD55E5968d00670CA9d95Caf',
        '0xbc106ee0781d8f25c70558f1B60e480A72E3d299',
        '0x04e292752193194e096c653300d3516d63DA481A',
        '0x5d078c0A14A065EFf9E6A8a71c47576f78664dB5',
        '0x7F05901b6Df571f7b50F3FC5763b6ea658cf8635',
        '0x914aac1739fA2aa4ae8afdb3C05102e1f71D3b09',
        '0xE25644FDeFDACA4ab30C94ADc1E1F6aaC10FC7D6',
        '0x84F799e8Ec360010f9e9F442335beDf8825D8553',
        '0xc4c4ab2D0E9a154A98912a19eA5ac591dB0094C8',
        '0x9cA90dF4c916ff1326BF59498D08C15967332320',
        '0x41818100D985e2626729fc98F78da80e2E704970',
        '0x5BB409621e4F493712F2bd832c7297EB7119ef19',
        '0xDc3e85938FD77102D098CcF865B1d58ff0763162',
        '0xc3D6aFA9aC3185F112ff172bAeB8D18BaEB3F37D',
        '0x939c91d63040A7859fbc9bca4e83e067bD1ED7ec',
        '0x2CecbaC8B69d3E66B5b1dfC0237f07821e528089'
      ]


    let owner = accounts[0];
    let firstAirline = accounts[1];

    let flightSuretyData = await FlightSuretyData.new();
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);

    
    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};