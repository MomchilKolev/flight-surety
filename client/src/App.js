import React, { useState, useEffect } from "react";
import { BigNumber } from "bignumber.js";

import "./App.css";
import useWeb3 from "./useWeb3";

const App = () => {
  const { loading, error, data } = useWeb3();

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error.message}</p>;

  const { web3, accounts, appContract, dataContract, flights } = data;

  return (
    <div className="App">
      <header className="header">Current account: {accounts[0]}</header>
      <div className="main">
        <p className="description">
          You can buy insurance up to 1 ether in case the flight is delayed due
          to airline fault. In case of delay you will receive 1.5x the amount
          insured against. Prices are shown in ether.
        </p>
        <div className="flights">
          {flights.map((f) => (
            <Flight
              {...f}
              key={f.key}
              flightKey={f.key}
              appContract={appContract}
              dataContract={dataContract}
              accounts={accounts}
              web3={web3}
            />
          ))}
        </div>
        <Sidebar appContract={appContract} dataContract={dataContract} accounts={accounts} web3={web3}/>
      </div>
    </div>
  );
};

const Flight = (props) => {
  const [state, setState] = useState("");
  const [insurance, setInsurance] = useState({
    insuranceAmount: 0,
    creditedAmount: 0,
  });

  useEffect(() => {
    props.appContract.methods
      .getInsurance(props.flightKey)
      .call({ from: props.accounts[0] })
      .then(({ insuranceAmount, creditedAmount }) => {
        console.log({ insuranceAmount, creditedAmount });
        setInsurance({ insuranceAmount, creditedAmount });
      });
  }, []);

  useEffect(() => {
    props.dataContract.events
      .FlightStatusInfo({ filter: { flightKey: props.flightKey } })
      .on("data", async (data) => {
        const { returnValues } = data;
        console.log("returnValues is", returnValues);
        if (returnValues.status == 20) {
          props.appContract.methods
            .getInsurance(props.flightKey)
            .call({ from: props.accounts[0] })
            .then(({ insuranceAmount, creditedAmount }) => {
              console.log({ insuranceAmount, creditedAmount });
              setInsurance({ insuranceAmount, creditedAmount });
            });
        }
      });
  }, []);

  const handleChange = (e) => {
    setState(e.target.value);
  };

  const handleClick = async (e) => {
    await props.appContract.methods.buyInsurance(props.flightKey).send({
      from: props.accounts[0],
      value: props.web3.utils.toWei(state, "ether"),
    });
  };

  const handleFlightStatusRequest = async (e) => {
    await props.appContract.methods
      .fetchFlightStatus(
        props.airline,
        props.flight,
        props.timestamp,
        props.flightKey
      )
      .send({ from: props.accounts[0] });
  };

  return (
    <div className="flight">
      <h2>{props.flight}</h2>
      <p>Airline: {props.airline}</p>
      <p>Leaving {getDate(props.timestamp)}</p>
      <input
        type="number"
        value={state}
        onChange={handleChange}
        max="1"
        min="0"
        step="0.000001"
      />
      <p>
        You have purchased insurance in the amount of{" "}
        {props.web3.utils.fromWei(`${insurance.insuranceAmount}`, "ether")}{" "}
        ether
      </p>
      <button type="button" onClick={handleClick}>
        Buy Insurance
      </button>
      <button type="button" onClick={handleFlightStatusRequest}>
        Request Flight Status
      </button>
    </div>
  );
};

function getDate(timestamp) {
  const date = new Date(+timestamp);
  const day = date.getDate();
  const month = date.getMonth();
  const year = date.getFullYear();
  const hours = date.getHours();
  const minutes = date.getMinutes();

  return `${+day}/${+month}/${+year} at ${hours}:${minutes}`;
}

const Sidebar = (props) => {
  const [state, setState] = useState(0);

  useEffect(() => {
    props.dataContract.events
      .FlightStatusInfo({ filter: { flightKey: props.flightKey } })
      .on("data", async (data) => {
        const { returnValues } = data;
        console.log('returnValues', returnValues)
        if (returnValues.status == 20) {
          props.appContract.methods.getCredit().call({ from: props.accounts[0] }).then(res => {
            setState(props.web3.utils.fromWei(`${res}`, "ether"))
          })
        }
      });
      props.appContract.methods.getCredit().call({ from: props.accounts[0] }).then(res => {
        setState(props.web3.utils.fromWei(`${res}`, "ether"))
      })
  }, []);

  const handleWithdraw = async (e) => {
    try {
      await props.appContract.methods.withdraw().send({ from: props.accounts[0], gas: 1999999 })
    } catch (err) {
    }
  };

  return (
    <div className="sidebar">
      <p>You have {state ? `${state} ether available for withdrawal` : 'Nothing to withdraw'}</p>
      <button
        type="button"
        onClick={handleWithdraw}
        disabled={state == 0}
      >
        Withdraw
      </button>
    </div>
  );
};

export default App;
