// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollatz {
  function collatzIteration(uint256 n) external pure returns (uint256);
}

contract CollatzPuzzle is ICollatz {
  function collatzIteration(uint256 n) public pure override returns (uint256) {
    if (n % 2 == 0) {
      return n / 2;
    } else {
      return 3 * n + 1;
    }
  }

  function ctf(address addr) external view returns (bool) {
    // check code size
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    require(size > 0 && size <= 32, "bad code size!");

    // check results to be matching
    uint p;
    uint q;
    for (uint256 n = 1; n < 200; n++) {
      // local result
      q = p = n;
      for (uint256 i = 0; i < 5; i++) {
        p = collatzIteration(p);
        q = ICollatz(addr).collatzIteration{gas: 100}(q);
      }
      require(p == q, "result mismatch!");
    }

    return true;
  }
}