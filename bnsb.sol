pragma solidity ^0.4.24;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Token {
    function balanceOf(address) public view returns (uint256) {}

    function transferFrom(
        address,
        address,
        uint256
    ) public returns (bool) {}

    function transfer(address, uint256) public returns (bool) {}
}

contract StandardToken is Token {
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => uint256) balances;

    uint256 public totalSupply;
    uint256 public totalPossibleSupply;
    address public owner;

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        if (balances[msg.sender] >= _value && _value >= 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (
            balances[_from] >= _value &&
            _value >= 0 &&
            allowed[_from][msg.sender] >= _value
        ) {
            balances[_to] = balances[_to].add(_value);
            allowed[_from][msg.sender] = SafeMath.sub(
                allowed[_from][msg.sender],
                _value
            );
            balances[_from] = balances[_from].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function balanceOf(address _from) public view returns (uint256 balance) {
        return balances[_from];
    }
}

contract MintableToken is StandardToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Burn(address sender, uint256 tokencount);

    bool public mintingFinished = false;
    address private potentialAdmin;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        canMint
        returns (bool)
    {
        require(
            totalSupply.add(_amount) < totalPossibleSupply,
            "The totalSupply can't be more than 21 million"
        );
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function resumeMinting() public onlyOwner returns (bool) {
        mintingFinished = false;
        return true;
    }

    function burn(uint256 value) public onlyOwner {
        totalSupply = totalSupply.sub(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        emit Burn(msg.sender, value);
    }

    function changeOwner(address owner_) public {
        if (msg.sender != owner) revert();
        potentialAdmin = owner_;
    }

    function becomeOwner() public {
        if (potentialAdmin == msg.sender) owner = msg.sender;
    }
}

contract CoinBNSB is MintableToken {
    function() public {
        revert();
    }

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = "H1.0";

    constructor() public {
        owner = msg.sender;
        balances[msg.sender] = 0;
        totalSupply = 0;
        totalPossibleSupply = 2100000000000000;
        name = "BNSB Token";
        decimals = 8;
        symbol = "BNSB";
    }
}
