# Ethernaut: 17. Recovery

> A contract creator has built a very simple token factory contract. Anyone can create new tokens with ease. After deploying the first token contract, the creator sent 0.001 ether to obtain more tokens. They have since lost the contract address.
>
> This level will be completed if you can recover (or remove) the 0.001 ether from the lost contract address.

**Objective of CTF:**

- Recover the funds from the contract.

**Target contract:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Recovery {
  //generate tokens
  function generateToken(string memory _name, uint256 _initialSupply) public {
    new SimpleToken(_name, msg.sender, _initialSupply);
  }
}

contract SimpleToken {
  using SafeMath for uint256;
  // public variables
  string public name;
  mapping(address => uint) public balances;

  // constructor
  constructor(string memory _name, address _creator, uint256 _initialSupply) {
    name = _name;
    balances[_creator] = _initialSupply;
  }

  // collect ether in return for tokens
  receive() external payable {
    balances[msg.sender] = msg.value.mul(10);
  }

  // allow transfers of tokens
  function transfer(address _to, uint _amount) public {
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = _amount;
  }

  // clean up after ourselves
  function destroy(address payable _to) public {
    selfdestruct(_to);
  }
}
```

My initial solution was to check the internal transactions of the contract creation transaction of my level instance. There, we can very well see the "lost" contract address, and we will call the `destroy` function there. To call a function with arguments, you need to provide a `calldata` (see [here](https://docs.soliditylang.org/en/latest/abi-spec.html#examples)). The arguments are given in chunks of 32-bytes, but the first 4 bytes of the `calldata` indicate the function to be called. That is calculated by the first 4 bytes of the function's canonical form. There are several ways to find it:

- Use a tool online, such as the [one I wrote](https://www.erhant.me/tools/ethertools).
- Write a bit of Solidity code and calculate `bytes4(keccak256("destory(address)"))`, which requires you to hand-write the canonical form.
- Write a small contract and run it locally (such as Remix IDE with VM) as follows:

```solidity
contract AAA {
  // this is the same function from ethernaut
  function destroy(address payable _to) public {
    selfdestruct(_to);
  }

  // we can directly find its selector
  function print() public pure returns (bytes4) {
    return this.destroy.selector;
  }
}
```

With any of the methods above, we find the function selector to be `0x00f55d9d`. We can then call the `destroy` function as follows:

```js
const functionSelector = '0x00f55d9d';
await web3.eth.sendTransaction({
  from: player,
  to: '0x559905e90cF45D7495e63dA1baEFB54d63B1436A', // the lost & found address
  data: web3.utils.encodePacked(functionSelector, web3.utils.padLeft(player, 64)),
});
```

## Original Solution

Upon sending my solution to Ethernaut, I have learned the actual solution in the message afterwards! Turns out that contract addresses are deterministic and are calculated by `keccack256(RLP_encode(address, nonce))`. The nonce for a contract is the number of contracts it has created. All nonce's are 0 for contracts, but they become 1 once they are created (their own creation makes the nonce 1).

Read about RLP encoding in the Ethereum docs [here](https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp). We want the RLP encoding of a 20 byte address and a nonce value of 1, which corresponds to the list such as `[<20 byte string>, <1 byte integer>]`.

For the string:

> if a string is 0-55 bytes long, the RLP encoding consists of a single byte with value 0x80 (dec. 128) plus the length of the string followed by the string. The range of the first byte is thus [0x80, 0xb7] (dec. [128, 183]).

For the list, with the string and the nonce in it:

> if the total payload of a list (i.e. the combined length of all its items being RLP encoded) is 0-55 bytes long, the RLP encoding consists of a single byte with value 0xc0 plus the length of the list followed by the concatenation of the RLP encodings of the items. The range of the first byte is thus [0xc0, 0xf7] (dec. [192, 247]).

This means that we will have:

```text
[
  0xC0
    + 1 (a byte for string length)
    + 20 (string length itself)
    + 1 (nonce),
  0x80
    + 20 (string length),
  <20 byte string>,
  <1 byte nonce>
]
```

In short: `[0xD6, 0x94, <address>, 0x01]`. We need to find the `keccak256` of the packed version of this array, which we can find via:

```js
web3.utils.soliditySha3(
  '0xd6',
  '0x94',
  // <instance address>,
  '0x01'
);
```

What is different with `soliditySha3` rather than `sha3` is that this one will encode-packed the parameters like Solidity would; hashing afterwards. The last 20 bytes of the resulting digest will be the contract address! Calling the `destroy` function is same as above.
