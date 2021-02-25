# How to run

1. Install Ganache from https://www.trufflesuite.com/ganache and truffle using `npm i -g truffle` or use `npx truffle ...`

2. Create a new Ethereum workspace with at least 50 accounts (configurable during creation)

3. Run `truffle migrate --reset`

4. CD into server

5. Run `npm i`

6. Run `npm run server`
- this will register all oracles and prepare for flight status requests

7. Copy accs from output or ganache into config/testConfig and replace testAddresses

8. Setup Metamask
- Install metamask
- Create account if necessary
- Import first ganache account by clicking on the circle top-right in metamask -> Import and pasting the private key of the very first ganache acc
- Change network to Localhost 7545, if it doesn't exist, create it:
  - Network name: Localhost 7545
  - New RPC Url: http://localhost:7545
  - Chaid ID: 1337
- Connect account (below fox on top-right)

9.  Open new terminal

10.  Run `truffle test` to confirm all tests pass

11. CD into client

12. Run `npm i`

13. Run `npm start`

14. A new tab should be opened with website at localhost:3000

15. Purchase insurance for a flight

16. Request Flight insurance until the withdraw button becomes available (waiting for a specific status, which has a 1/5 chance of being picked)

17. Withdraw

Fin