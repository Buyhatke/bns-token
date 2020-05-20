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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract TradeEngine{
    
  function balanceOf(address token, address user) public view returns (uint balance) {}

  function orderBNS(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address customerAddress) public returns(bool success){}
    
  function deductFee(address payer, address token, uint amount) public returns (bool res) {}
  
}

contract Token {
    
  function tokenBalanceOf(address token, address user) public view returns (uint) {}

  function balanceOf(address _owner) public view returns (uint256 balance) {}

  function transfer(address _to, uint256 _value) public returns (bool success) {}

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
  
  function frozenBalanceOf(address _from) public view returns (uint256 balance) {}
  
  function issueMulti(address[] _to, uint256[] _value, uint256 ldays, uint256 period) public returns (bool success) {}
  
  function lockTime(address _from) public view returns (uint256 time) {}
  
  function subscribe( address merchantAddress, address customerAddress, address token, uint256 value, uint256 period ) public returns(uint256 oID){}
  
  function charge(uint256 orderId) public returns (bool success) {}
  
  function subscribeToSpp(address customerAddress, uint256 value, uint256 period,address tokenGet,address tokenGive) public returns (uint256 sID){}
  
  function closeSpp(uint256 sppID)public returns(bool success) {}
  
  function getSppIdFromHash(bytes32 hash) public returns(uint256 sppID) {}
  
  function setLastPaidAt(bytes32 hash) public returns(bool success) {}
  
  function setRemainingToBeFulfilled(bytes32 hash, uint256 amt) public returns(bool success) {}
  
  function getRemainingToBeFulfilled(bytes32 hash) public returns(uint256 res) {}
  
  function getlistOfSubscriptions(address _from) public view returns(uint256[] arr) {}
  
  function getlistOfSppSubscriptions(address _from) public view returns(uint256[] arr) {}
  
  function getcurrentTokenAmounts(uint256 sppID) public view returns(uint256[2] memory arr) {}
  
  function getTokenStats(uint256 sppID) public view returns(address[2] memory arr) {}
  
  function setcurrentTokenStats(bytes32 hash, uint256 amountGotten, uint256 amountGiven) public returns (bool success) {}
  
  function getRemainingToBeFulfilled(uint256 sppID) public view returns(uint256 res) {} 

}

contract StandardToken is Token {
    
    using SafeMath for uint256;
    
    event Subscribe( address merchantAddress, address customerAddress, address token, uint256 value, uint256 period );
    event Charge( uint256 orderId );
    event SubscribeToSpp( uint256 sppID, address customerAddress, uint256 value, uint256 period, address tokenGet, address tokenGive );
    event ChargeSpp( uint256 sppID );
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    event CloseSpp(uint256 sppID);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Mint(string hash, address account, uint256 value);
    event SetCurrentTokenStats(uint256 sppID, uint256 amountGotten, uint256 amountGiven);
    
    modifier _ownerOnly(){
      require(msg.sender == owner);
      _;
    }
    
    modifier _tradeEngineOnly(){
      require(msg.sender == TradeEngineAddress);
      _;
    }
    
    function mint(string hash,address account, uint256 value) public _ownerOnly {
        require(account != address(0));
        require(SafeMath.add(totalSupply,value)<=totalPossibleSupply,"totalSupply can't be more than the totalPossibleSupply");
        totalSupply = SafeMath.add(totalSupply,value);
        balances[account] = SafeMath.add(balances[account],value);
        emit Mint(hash, account, value);
    }
    
    function burn(address account, uint256 value) public _ownerOnly {
        require(account != address(0)); //can account be bns contract address?? YES!!!!
        totalSupply = totalSupply.sub(value); 
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value>=0 && userdata[msg.sender].exists==false){
              balances[msg.sender] = balances[msg.sender].sub(_value);
              balances[_to] = balances[_to].add(_value);
              emit Transfer(msg.sender, _to, _value);
              return true;
        }
        else { return false; }
    }

   function issueMulti(address[] _to, uint256[] _value, uint256 ldays, uint256 period) public _ownerOnly returns (bool success) {
       require(_value.length<=20,"too long array");
       require(_value.length==_to.length,"array size misatch");
       uint256 sum = 0;
       for(uint i=0;i<_value.length;i++){
           sum = sum.add(_value[i]);
       }
       if (balances[msg.sender] >= sum && sum > 0) {
           balances[msg.sender] = balances[msg.sender].sub(sum);
           for(uint j=0;j<_to.length;j++){
             balances[_to[j]] = balances[_to[j]].add(_value[j]);
             userdata[_to[j]].exists = true;
             userdata[_to[j]].frozen_balance = userdata[_to[j]].frozen_balance.add(_value[j]);
             userdata[_to[j]].lock_till = now.add((ldays.mul(86400)));
             userdata[_to[j]].time_period = (period.mul(86400));
             userdata[_to[j]].per_tp_release_amt = SafeMath.div(userdata[_to[j]].frozen_balance,(ldays.div(period)));
             emit Transfer(msg.sender, _to[j], _value[j]);
           }
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
      
      if (balances[_from] >= _value &&  _value >= 0 && (allowed[_from][msg.sender] >= _value || _from==msg.sender)) {
          
            if(userdata[_from].exists==false){
                balances[_to] = balances[_to].add(_value);
                if(_from!=msg.sender) allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
                balances[_from] = balances[_from].sub(_value);
                emit Transfer(_from, _to, _value);
                return true;
            }
            
            uint lock = userdata[_from].lock_till;
            
            if(now >= lock){
                userdata[_from].frozen_balance = 0;
                userdata[_from].exists = false;
                balances[_to] = SafeMath.add(balances[_to],_value);
                if(_from!=msg.sender) allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
                balances[_from] = SafeMath.sub(balances[_from],_value);
                emit Transfer(_from, _to, _value);
                return true;
            }
            
            uint256 a = (lock-now);
            uint256 b = userdata[_from].time_period;
            // uint256 should_be_frozen = ((a+b-1)/b)*userdata[_from].per_tp_release_amt;// safemath
            uint256 should_be_frozen = SafeMath.mul((SafeMath.div(a,b) + 1),userdata[_from].per_tp_release_amt);
            
            if(userdata[_from].frozen_balance > should_be_frozen){
                userdata[_from].frozen_balance = should_be_frozen;
            }
            
            if(balances[_from].sub(_value)>=userdata[_from].frozen_balance){   
                balances[_to] = balances[_to].add(_value);
                if(_from!=msg.sender) allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
                balances[_from] = balances[_from].sub(_value);
                emit Transfer(_from, _to, _value);
                return true;  
            }
            
            return false;
       } 
       else { return false; }
   }
   
    function balanceOf(address _from) public view returns (uint256 balance) {
        return balances[_from];
    }
   
    function frozenBalanceOf(address _from) public view returns (uint256 balance) { //need more checking here
        if(userdata[_from].exists==false) return ;
        
        uint lock = userdata[_from].lock_till;
        
        if(now >= lock) {
            userdata[_from].frozen_balance = 0;
            userdata[_from].exists = false;
            return 0;
        }
        
        uint256 a = (lock-now);
        uint256 b = userdata[_from].time_period;
        uint256 should_be_frozen = SafeMath.mul((SafeMath.div(a,b) + 1),userdata[_from].per_tp_release_amt);
            
        if(userdata[_from].frozen_balance > should_be_frozen){
            userdata[_from].frozen_balance = should_be_frozen;
        }
        
        return userdata[_from].frozen_balance;
    }
   
    function lockTime(address _from) public view returns (uint256 time) {
        if(userdata[_from].exists==false) revert();
        return userdata[_from].lock_till;
    }
    
    function deposit() public payable {
        tokens[0][msg.sender] = SafeMath.add(tokens[0][msg.sender], msg.value);
        emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function withdraw(uint amount) public{
        if (tokens[0][msg.sender] < amount) revert();
        tokens[0][msg.sender] = SafeMath.sub(tokens[0][msg.sender], amount);
        if (!msg.sender.call.value(amount)()) revert();
        emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }
    
    function depositToken(address token, uint amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        if (token==0) revert();
        if (!Token(token).transferFrom(msg.sender, this, amount)) revert();
        tokens[token][msg.sender] = SafeMath.add(tokens[token][msg.sender], amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdrawToken(address token, uint amount) public {
        if (token==0) revert();
        if (tokens[token][msg.sender] < amount) revert();
        tokens[token][msg.sender] = SafeMath.sub(tokens[token][msg.sender], amount);
        if (!Token(token).transfer(msg.sender, amount)) revert();
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function tokenBalanceOf(address token, address user) public view returns (uint) {
        return tokens[token][user];
    }
    
    function subscribe( address merchantAddress, address customerAddress, address token, uint256 value, uint256 period ) public returns(uint256 oID){
        if(customerAddress!=msg.sender || period<minPeriod){
            return 0;
        }
        if(tokens[token][msg.sender]>=value && value>0){
            orderId += 1;
            subscriptiondata[orderId].exists = true;
            subscriptiondata[orderId].value = value;
            subscriptiondata[orderId].period = period;
            subscriptiondata[orderId].lastPaidAt = now-period;
            subscriptiondata[orderId].merchantAddress = merchantAddress;
            subscriptiondata[orderId].customerAddress = customerAddress;
            subscriptiondata[orderId].tokenType = token;
            subList[customerAddress].arr.push(orderId);
            emit Subscribe( merchantAddress, customerAddress, token, value, period );
            return orderId;
        }
    }
    
    function charge(uint256 orderId) public returns (bool success){
        require(subscriptiondata[orderId].exists == true, "This subscription does not exist, wrong orderId");
        require(subscriptiondata[orderId].merchantAddress == msg.sender, "You are not the real merchant");
        require(subscriptiondata[orderId].lastPaidAt+subscriptiondata[orderId].period <= now, "charged too early");
        address token = subscriptiondata[orderId].tokenType;
        tokens[token][subscriptiondata[orderId].customerAddress] = tokens[token][subscriptiondata[orderId].customerAddress].sub(subscriptiondata[orderId].value);
        uint256 fee = ((subscriptiondata[orderId].value).mul(25)).div(10000);
        tokens[token][feeAccount] = SafeMath.add(tokens[token][feeAccount],fee);
        tokens[token][subscriptiondata[orderId].merchantAddress] = tokens[token][subscriptiondata[orderId].merchantAddress].add((subscriptiondata[orderId].value.sub(fee)));
        subscriptiondata[orderId].lastPaidAt = SafeMath.add(subscriptiondata[orderId].lastPaidAt,subscriptiondata[orderId].period);
        emit Charge( orderId );
        return true;
    }
    
    function closeSubscription(uint256 orderId) public returns (bool success){
        require(subscriptiondata[orderId].exists == true, "This subscription does not exist, wrong orderId OR already closed");
        require(subscriptiondata[orderId].customerAddress == msg.sender, "You are not the customer of this orderId");
        subscriptiondata[orderId].exists = false;
        return true;
    }
   
    function subscribeToSpp(address customerAddress, uint256 value, uint256 period,address tokenGet,address tokenGive) public returns (uint256 sID){
        if(customerAddress != msg.sender || period<86400){
            return 0;
        }
        if( TradeEngine(TradeEngineAddress).balanceOf(tokenGive,customerAddress)>=value ){
            require(TradeEngine(TradeEngineAddress).deductFee(customerAddress, usdt, uint(2*(10**usdtDecimal))),"fee not able to charge");
            sppID += 1;
            sppSubscriptionStats[sppID].exists = true;
            sppSubscriptionStats[sppID].customerAddress = customerAddress;
            sppSubscriptionStats[sppID].tokenGet = tokenGet;
            sppSubscriptionStats[sppID].tokenGive = tokenGive;
            sppSubscriptionStats[sppID].value = value;
            sppSubscriptionStats[sppID].remainingToBeFulfilled = value;
            sppSubscriptionStats[sppID].period = period;
            sppSubscriptionStats[sppID].lastPaidAt = now-period;
            tokenStats[sppID].TokenToGet = tokenGet;
            tokenStats[sppID].TokenToGive = tokenGive;
            sppSubList[customerAddress].arr.push(sppID);
            emit SubscribeToSpp( sppID, customerAddress, value, period, tokenGet, tokenGive );
            return sppID;
        }
    }
    
    function chargeSpp(uint256 sppID, uint256 amountGet, uint256 amountGive, uint256 expires ) public _ownerOnly {
        require(amountGive==sppSubscriptionStats[sppID].remainingToBeFulfilled,"check");
        require(onGoing[sppID]<block.number,"chargeSpp is already onGoing for this sppId");
        require(sppSubscriptionStats[sppID].exists==true,"This SPP does not exist, wrong SPP ID");
        require(sppSubscriptionStats[sppID].lastPaidAt+sppSubscriptionStats[sppID].period<=now,"Charged too early");
        require(TradeEngine(TradeEngineAddress).deductFee(sppSubscriptionStats[sppID].customerAddress, usdt, uint(2*rateTrxUsdt)),"fee unable to charge");// need to multiply with 10^8??
        nonce += 1;
        bytes32 hash = sha256(TradeEngineAddress, sppSubscriptionStats[sppID].tokenGet, amountGet , sppSubscriptionStats[sppID].tokenGive, amountGive, block.number+expires, nonce);
        hash2sppId[hash] = sppID;
        onGoing[sppID] = block.number+expires;
        TradeEngine(TradeEngineAddress).orderBNS(sppSubscriptionStats[sppID].tokenGet, amountGet, sppSubscriptionStats[sppID].tokenGive, amountGive, block.number+expires, nonce, sppSubscriptionStats[sppID].customerAddress);
        emit ChargeSpp( sppID );
    }
    
    function closeSpp(uint256 sppID) public returns(bool success){
        if(msg.sender!=sppSubscriptionStats[sppID].customerAddress) return false;
        sppSubscriptionStats[sppID].exists = false;
        emit CloseSpp( sppID );
        return true;
    }
    
    function setrateTrxUsdt(uint256 _value) public _ownerOnly returns(bool res){
        rateTrxUsdt = _value;
        return true;
    }
    
    function setAddresses(address usdt1, address feeAccount1) public _ownerOnly returns (bool res){
      usdt = usdt1;
      feeAccount = feeAccount1;
      return true;
    }
    
    function setUsdtDecimal(uint256 decimal) public _ownerOnly{
        usdtDecimal = decimal;
    }
    
    function setMinPeriod(uint256 p) public _ownerOnly {
        minPeriod = p;
    } 
    
    function setLastPaidAt(bytes32 hash) public returns(bool success){
        if(msg.sender!=TradeEngineAddress) return false;
        if ( (now - (sppSubscriptionStats[hash2sppId[hash]].lastPaidAt + sppSubscriptionStats[hash2sppId[hash]].period))<14400 ){
            sppSubscriptionStats[hash2sppId[hash]].lastPaidAt = sppSubscriptionStats[hash2sppId[hash]].lastPaidAt.add(sppSubscriptionStats[hash2sppId[hash]].period);
        }
        else{
            sppSubscriptionStats[hash2sppId[hash]].lastPaidAt = now;
        }
        return true;
    }
    
    function setTradeEngineAddress(address _add) public _ownerOnly returns (bool success){
        TradeEngineAddress = _add;
        return true;
    }
    
    function setRemainingToBeFulfilled(bytes32 hash, uint256 amt) public returns(bool success){
        if(msg.sender!=TradeEngineAddress) return false;
        if((sppSubscriptionStats[hash2sppId[hash]].remainingToBeFulfilled == amt)) sppSubscriptionStats[hash2sppId[hash]].remainingToBeFulfilled = sppSubscriptionStats[hash2sppId[hash]].value;
        else{
            sppSubscriptionStats[hash2sppId[hash]].remainingToBeFulfilled = sppSubscriptionStats[hash2sppId[hash]].remainingToBeFulfilled.sub(amt);
        }
        return true;
    }
    
    function setcurrentTokenStats(bytes32 hash, uint256 amountGotten, uint256 amountGiven) public returns (bool success){
        if(msg.sender!=TradeEngineAddress) return false;
        tokenStats[hash2sppId[hash]].amountGotten = tokenStats[hash2sppId[hash]].amountGotten.add(amountGotten);
        tokenStats[hash2sppId[hash]].amountGiven = tokenStats[hash2sppId[hash]].amountGiven.add(amountGiven);
        emit SetCurrentTokenStats(hash2sppId[hash], amountGotten, amountGiven);
        return true;
    }
    
    function isActiveSpp(uint256 sppID) public view returns(bool res){
        return sppSubscriptionStats[sppID].exists;
    }
    
    function getSppIdFromHash(bytes32 hash) public returns(uint256 sppID){
        return hash2sppId[hash];
    }
    
    function getLatestOrderId() public view returns(uint256 oId){
        return orderId;
    }
    
    function getRemainingToBeFulfilled(bytes32 hash) public _tradeEngineOnly returns(uint256 res){
        // if(msg.sender!=TradeEngineAddress) return;
        return sppSubscriptionStats[hash2sppId[hash]].remainingToBeFulfilled;
    }
    
    function getRemainingToBeFulfilled(uint256 sppID) public view returns(uint256 res){
        return sppSubscriptionStats[sppID].remainingToBeFulfilled;
    }
    
    function getlistOfSubscriptions(address _from) public view returns(uint256[] arr){
        return subList[_from].arr;
    }
    
    function getlistOfSppSubscriptions(address _from) public view returns(uint256[] arr){
        return sppSubList[_from].arr;
    }
    
    function getcurrentTokenAmounts(uint256 sppID) public view returns(uint256[2] memory arr){
        arr[0] = tokenStats[sppID].amountGotten;
        arr[1] = tokenStats[sppID].amountGiven;
        return arr;
    }
    
    function getTokenStats(uint256 sppID) public view returns(address[2] memory arr){
        arr[0] = tokenStats[sppID].TokenToGet;
        arr[1] = tokenStats[sppID].TokenToGive;
        return arr;
    }
    
    function getLatestSppId() public view returns(uint256 sppId){
        return sppID;
    }
    
    function getTimeRemainingToCharge(uint256 sppID) public view returns(uint256 time){
        return ((sppSubscriptionStats[sppID].lastPaidAt+sppSubscriptionStats[sppID].period)-now);
    }
    
    struct sppSubscribers {
        bool exists;
        address customerAddress;
        address tokenGive;
        address tokenGet;
        uint256 value;
        uint256 period;
        uint256 lastPaidAt;
        uint256 remainingToBeFulfilled;
    }
    
    struct currentTokenStats {
        address TokenToGet;
        uint256 amountGotten;
        address TokenToGive;
        uint256 amountGiven;
    }
    
    struct listOfSubscriptions {
       uint256[] arr;
    }
   
    struct listOfSppByAddress {
       uint256[] arr;
    }
    
    mapping (uint256 => currentTokenStats) tokenStats;
    mapping (address => listOfSppByAddress) sppSubList;
    mapping (address => listOfSubscriptions) subList;
    mapping (bytes32 => uint256) public hash2sppId;
    mapping (uint256 => uint256) public onGoing;
    mapping (uint256 => sppSubscribers) public sppSubscriptionStats;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => mapping (address => uint)) public tokens;
    mapping (address => userstats) public userdata;
    mapping (address => uint256) public balances;
    mapping (uint256 => subscriptionstats) public subscriptiondata;
   
    struct userstats {
        uint256 per_tp_release_amt;
        uint256 time_period; 
        uint256 frozen_balance;
        uint256 lock_till;
        bool exists;
    }
   
    struct subscriptionstats {
       uint256 value;
       uint256 period; 
       uint256 lastPaidAt;
       address merchantAddress;
       address customerAddress;
       address tokenType;
       bool exists;
    }
   
    uint256 public totalSupply;
    uint256 public totalPossibleSupply;
    uint256 public orderId;
    address owner;
    address public TradeEngineAddress;
    uint256 sppID;
    address usdt;
    uint256 usdtDecimal;
    uint256 rateTrxUsdt;
    uint256 nonce;
    address public feeAccount;
    uint256 minPeriod;
}

contract CoinBNS is StandardToken {
  function () {
      revert();
  }
  string public name;        
  uint8 public decimals;             
  string public symbol;          
  string public version = 'H1.0';
  constructor() public {
      owner = msg.sender;
      balances[msg.sender] = 250000000000000000;
      totalSupply = 250000000000000000;
      totalPossibleSupply = 250000000000000000;
      name = "BNS Token";
      decimals = 8;
      symbol = "BNS";
  }
}