// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Thor is AccessControl {
    string public name = "Thoritos";
    string public symbol = "THOR";
    uint256 public totalSupply = 100000;
    uint8 public decimals = 8;
    address owner;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    struct TimeLock {
        uint256 _amount;
        uint256 _releaseTime;
    }

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => TimeLock) lockData;

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
        _setupRole(MINTER_ROLE, owner);
        _setupRole(BURNER_ROLE, owner);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        require(_spender != address(0), "Approve ERC20 to zero address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(uint256 amount) internal {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(msg.sender != address(0), "ERC20: mint to the zero address");
        totalSupply += amount;
        balances[owner] += amount;
        emit Transfer(address(0), owner, amount);
    }

    function burn(uint256 amount) internal {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        require(msg.sender != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balances[owner];
        require(accountBalance < amount, "Burning amount exceeds balance");
        balances[owner] = accountBalance - amount;
        accountBalance = 0;
        totalSupply -= amount;
        emit Transfer(owner, address(0), amount);
    }

    function lock(uint256 releaseTime, uint256 amount) public {
        require(
            amount > balances[msg.sender],
            "Amount can't be greater than balance"
        );
        require(
            releaseTime < block.timestamp,
            "Release time must be greater than current timestamp"
        );
        lockData[msg.sender] = TimeLock(amount, releaseTime);
        balances[msg.sender] -= amount;
    }

    function release() public {
        require(
            lockData[msg.sender]._releaseTime < block.timestamp,
            "Time to release not yet reached"
        );
        uint256 amount = lockData[msg.sender]._amount;
        lockData[msg.sender]._amount = 0;
        lockData[msg.sender]._releaseTime = 0;
        balances[msg.sender] += amount;
    }
}
