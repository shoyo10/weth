// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWEthEvent  {
    event Deposit(address indexed sender, uint256 value);
	event Withdraw(address indexed account, uint256 value);
}

contract WrapEth is IERC20, IWEthEvent {
    string private  _name = "WETH";
    string private  _symbol = "WETH";
    uint8 private  _decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) _allowances;

    // ETH to WETH
    function deposit() external payable {
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // WETH to ETH
    function withdraw(uint256 amount) external {
        require(amount <= _balances[msg.sender]);
        _balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return payable(address(this)).balance;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "can't transfer to the zero address");
        require(amount <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender] - amount;
        _balances[to] = _balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "spender can't be the zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint) {
        return _allowances[_owner][_spender];
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(amount <= _balances[from]);
        require(amount <= _allowances[from][msg.sender]);

        _balances[from] = _balances[from] - amount;
        _allowances[from][msg.sender] = _allowances[from][msg.sender] - amount;
        _balances[to] = _balances[to] + amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
