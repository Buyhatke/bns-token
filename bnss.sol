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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Token {
   
   function balanceOf(address _from) public view returns (uint256 balance) {}
   
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
   
   function transfer(address _to, uint256 _value) public returns (bool success) {}
   
}

contract StandardToken is Token {
    
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    uint256 sppID;
    uint256 public totalSupply;
    address public owner;
    address private potentialAdmin;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value>=0){
              balances[msg.sender] = balances[msg.sender].sub(_value);
              balances[_to] = balances[_to].add(_value);
              emit Transfer(msg.sender, _to, _value);
              return true;
        }
        else { return false; }
    }
   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value &&  _value >=0 && allowed[_from][msg.sender] >= _value) {
            balances[_to] = balances[_to].add(_value);
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
            balances[_from] = balances[_from].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
      }
      else { return false; }
    }
    
    function balanceOf(address _from) public view returns (uint256 balance) {
        return balances[_from];
    }

    function changeOwner(address owner_) public {
    if (msg.sender != owner) revert();
        potentialAdmin = owner_;
    }
  
    function becomeOwner() public {
      if(potentialAdmin==msg.sender) owner = msg.sender;
    }
    
}

contract CoinBNSS is StandardToken {
    
   function () public {
       revert();
   }
   
   string public name;                   
   uint8 public decimals;                 
   string public symbol;          
   string public version = 'H1.0';
   constructor() public {
       owner = msg.sender;
       balances[msg.sender] = 160000000000000000;
       totalSupply = 160000000000000000;
       name = "BNSS Token";
       decimals = 8;
       symbol = "BNSS";
   }
}