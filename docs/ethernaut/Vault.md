# Ethernaut: 8. Vault

**Objective of CTF:**

- Unlock the vault.

**Target contract:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Vault {
  bool public locked;
  bytes32 private password;

  constructor(bytes32 _password) public {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
}
```

Here we recall the golden rule: everything on the blockchain is there for everyone to see, and it will always be there. As such, we can find out the password that was used in construction of the contract. There are actually two ways to do it:

**Find the password by looking at the contract creation transaction**: The contract creation code is composed of contract ABI encoded and the parameters. Therefore some of the digits we see there at the end are `constructor` arguments. We know that there is only one argument: password (32 bytes). In hexadecimals it is 64 characters, so we can check the final 64 characters of the contract creation code and that is the password. Note that while calling the `unlock` function you should add `0x` at the beginning of the string.

**Find the password by looking at the storage variables**: Looking at the Vault contract, the storage is read from top to bottom. EVM has `2 ^ 256}` slots with a 32-byte value stored in each. At the top, we have `bool public locked` and after that we have `bytes32 private password;`. These variable are at index 0 and 1 in the storage respectively. We can therefore read the password via:

```js
await web3.eth.getStorageAt(contract.address, 1);
```

and simply give the result as the parameter to `contract.unlock(...)`.
