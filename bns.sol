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

contract TradeEngine {
    function balanceOf(address, address) public view returns (uint256) {}

    function orderBNS(address, uint256, address, uint256, uint256, uint256, address) public returns (bool) {}

    function deductFee(address, address, uint256) public returns (bool) {}
}

contract Token {
    function tokenBalanceOf(address, address) public view returns (uint256) {}

    function transfer(address, uint256) public returns (bool) {}

    function transferFrom(address, address, uint256) public returns (bool) {}

    function subscribe(address,address,address,uint256,uint256) public returns (uint256) {}

    function charge(uint256) public returns (bool) {}

    function subscribeToSpp(address,uint256,uint256,address,address) public returns (uint256) {}

    function closeSpp(uint256) public returns (bool) {}

    function getSppIdFromHash(bytes32) public returns (uint256) {}

    function setLastPaidAt(bytes32) public returns (bool) {}

    function setRemainingToBeFulfilled(bytes32, uint256) public returns (bool) {}

    function getRemainingToBeFulfilledByHash(bytes32) public returns (uint256) {}

    function getlistOfSubscriptions(address) public view returns (uint256[]) {}

    function getlistOfSppSubscriptions(address) public view returns (uint256[]) {}

    function getcurrentTokenAmounts(uint256) public view returns (uint256[2] memory) {}

    function getTokenStats(uint256) public view returns (address[2] memory) {}

    function setcurrentTokenStats( bytes32, uint256, uint256) public returns (bool) {}

    function getRemainingToBeFulfilledBySppID(uint256) public view returns (uint256) {}
}

contract BNSToken is Token {
    using SafeMath for uint256;

    event Subscribe(uint256 indexed orderId, address indexed merchantAddress,address indexed customerAddress,address token,uint256 value,uint256 period);
    event Charge(uint256 orderId);
    event SubscribeToSpp(uint256 indexed sppID,address indexed customerAddress,uint256 value,uint256 period,address indexed tokenGet,address tokenGive);
    event ChargeSpp(uint256 sppID, uint256 expires, uint256 nonce);
    event Deposit(address indexed token,address indexed user,uint256 amount,uint256 balance);
    event Withdraw(address indexed token,address indexed user,uint256 amount,uint256 balance);
    event CloseSpp(uint256 sppID);
    event SetCurrentTokenStats(uint256 indexed sppID,uint256 amountGotten,uint256 amountGiven);

    modifier _ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    modifier _tradeEngineOnly() {
        require(msg.sender == TradeEngineAddress);
        _;
    }

    bool public scLock = false;

    modifier _ifNotLocked() {
        require(scLock == false);
        _;
    }

    function setLock() public _ownerOnly {
        scLock = !scLock;
    }

    function changeOwner(address owner_) public _ownerOnly {
        potentialAdmin = owner_;
    }

    function becomeOwner() public {
        if (potentialAdmin == msg.sender) owner = msg.sender;
    }

    function deposit() public payable {
        tokens[0][msg.sender] = SafeMath.add(tokens[0][msg.sender], msg.value);
        emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function withdraw(uint256 amount) public {
        if (tokens[0][msg.sender] < amount) revert();
        tokens[0][msg.sender] = SafeMath.sub(tokens[0][msg.sender], amount);
        if (!msg.sender.call.value(amount)()) revert();
        emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }

    function depositToken(address token, uint256 amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        if (token == 0) revert();
        if (!Token(token).transferFrom(msg.sender, this, amount)) revert();
        tokens[token][msg.sender] = SafeMath.add(tokens[token][msg.sender],amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) public {
        if (token == 0) revert();
        if (tokens[token][msg.sender] < amount) revert();
        tokens[token][msg.sender] = SafeMath.sub(tokens[token][msg.sender],amount);
        if (!Token(token).transfer(msg.sender, amount)) revert();
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function tokenBalanceOf(address token, address user) public view returns (uint256 balance)
    {
        return tokens[token][user];
    }

    function subscribe(address merchantAddress, address customerAddress, address token, uint256 value, uint256 period) public _ifNotLocked returns (uint256 oID) {
        if (customerAddress != msg.sender || period < minPeriod) {
            return 0;
        }
        if (tokens[token][msg.sender] >= value && value > 0) {
            orderId += 1;
            subscriptiondata[orderId] = subscriptionstats({
                exists: true,
                value: value,
                period: period,
                lastPaidAt: now.sub(period),
                merchantAddress: merchantAddress,
                customerAddress: customerAddress,
                tokenType: token
            });
            subList[customerAddress].arr.push(orderId);
            emit Subscribe(orderId,merchantAddress,customerAddress,token,value,period);
            return orderId;
        }
    }

    function charge(uint256 orderId) public _ifNotLocked returns (bool success)
    {
        subscriptionstats memory _orderData = subscriptiondata[orderId];
        require(_orderData.exists == true,"This subscription does not exist, wrong orderId");
        require(_orderData.merchantAddress == msg.sender,"You are not the real merchant");
        require((_orderData.lastPaidAt).add(_orderData.period) <= now,"charged too early");
        address token = _orderData.tokenType;
        tokens[token][_orderData.customerAddress] = tokens[token][_orderData.customerAddress].sub(_orderData.value);
        uint256 fee = ((_orderData.value).mul(25)).div(10000);
        tokens[token][feeAccount] = SafeMath.add(tokens[token][feeAccount],fee);
        tokens[token][_orderData.merchantAddress] = tokens[token][_orderData.merchantAddress].add((_orderData.value.sub(fee)));
        _orderData.lastPaidAt = SafeMath.add(_orderData.lastPaidAt,_orderData.period);
        subscriptiondata[orderId] = _orderData;
        emit Charge(orderId);
        return true;
    }

    function closeSubscription(uint256 orderId) public returns (bool success) {
        subscriptionstats memory _orderData = subscriptiondata[orderId];
        require(_orderData.exists == true,"This subscription does not exist, wrong orderId OR already closed");
        require(_orderData.customerAddress == msg.sender,"You are not the customer of this orderId");
        subscriptiondata[orderId].exists = false;
        return true;
    }

    function subscribeToSpp(address customerAddress,uint256 value,uint256 period,address tokenGet,address tokenGive) public _ifNotLocked returns (uint256 sID) {
        if (customerAddress != msg.sender || period < 86400) {
            return 0;
        }
        if (TradeEngine(TradeEngineAddress).balanceOf(tokenGive,customerAddress) >= value) {
            require(TradeEngine(TradeEngineAddress).deductFee(customerAddress,usdt,uint256(2 * (10**usdtDecimal))),"fee not able to charge");
            sppID += 1;
            sppSubscriptionStats[sppID] = sppSubscribers({
                exists: true,
                customerAddress: customerAddress,
                tokenGet: tokenGet,
                tokenGive: tokenGive,
                value: value,
                remainingToBeFulfilled: value,
                period: period,
                lastPaidAt: now - period
            });
            tokenStats[sppID] = currentTokenStats({
                TokenToGet: tokenGet,
                TokenToGive: tokenGive,
                amountGotten: 0,
                amountGiven: 0
            });
            sppSubList[customerAddress].arr.push(sppID);
            emit SubscribeToSpp(sppID,customerAddress,value,period,tokenGet,tokenGive);
            return sppID;
        }
    }

    function chargeSpp(uint256 sppID,uint256 amountGet,uint256 amountGive,uint256 expires) public _ownerOnly _ifNotLocked {
        sppSubscribers memory _subscriptionData = sppSubscriptionStats[sppID];
        require(amountGive == _subscriptionData.remainingToBeFulfilled,"check");
        require(onGoing[sppID] < block.number,"chargeSpp is already onGoing for this sppId");
        require(_subscriptionData.exists == true,"This SPP does not exist, wrong SPP ID");
        require(_subscriptionData.lastPaidAt + _subscriptionData.period <= now,"Charged too early");
        require(TradeEngine(TradeEngineAddress).deductFee(_subscriptionData.customerAddress,usdt,uint256(2 * rateEthUsdt)),"fee unable to charge"); //in matic, is this needed?
        nonce += 1;
        bytes32 hash = sha256(abi.encodePacked(TradeEngineAddress,_subscriptionData.tokenGet,amountGet,_subscriptionData.tokenGive,amountGive,block.number + expires,nonce));
        hash2sppId[hash] = sppID;
        onGoing[sppID] = block.number + expires;
        TradeEngine(TradeEngineAddress).orderBNS(_subscriptionData.tokenGet,amountGet,_subscriptionData.tokenGive,amountGive,block.number + expires,nonce,_subscriptionData.customerAddress);
        emit ChargeSpp(sppID, (block.number + expires), nonce);
    }

    function closeSpp(uint256 sppID) public returns (bool success) {
        if (msg.sender != sppSubscriptionStats[sppID].customerAddress) return false;
        sppSubscriptionStats[sppID].exists = false;
        emit CloseSpp(sppID);
        return true;
    }

    function setrateEthUsdt(uint256 _value) public _ownerOnly {
        rateEthUsdt = _value;
    }

    function setAddresses(address usdt1, address feeAccount1) public _ownerOnly {
        usdt = usdt1;
        feeAccount = feeAccount1;
    }

    function setUsdtDecimal(uint256 decimal) public _ownerOnly {
        usdtDecimal = decimal;
    }

    function setMinPeriod(uint256 p) public _ownerOnly {
        minPeriod = p;
    }

    function setTradeEngineAddress(address _add) public _ownerOnly {
        TradeEngineAddress = _add;
    }

    function setLastPaidAt(bytes32 hash) public returns (bool success) {
        if (msg.sender != TradeEngineAddress) return false;
        uint256 sppID = hash2sppId[hash];
        sppSubscribers memory _subscriptionData = sppSubscriptionStats[sppID];
        if ((now - (_subscriptionData.lastPaidAt + _subscriptionData.period)) < 14400) {
            sppSubscriptionStats[hash2sppId[hash]].lastPaidAt = _subscriptionData.lastPaidAt.add(_subscriptionData.period);
        } 
        else {
            sppSubscriptionStats[hash2sppId[hash]].lastPaidAt = now;
        }
        return true;
    }

    function setRemainingToBeFulfilled(bytes32 hash, uint256 amt) public returns (bool success)
    {
        if (msg.sender != TradeEngineAddress) return false;
        uint256 sppID = hash2sppId[hash];
        sppSubscribers memory _subscriptionData = sppSubscriptionStats[sppID];
        if ((_subscriptionData.remainingToBeFulfilled == amt))
            sppSubscriptionStats[hash2sppId[hash]].remainingToBeFulfilled = _subscriptionData.value;
        else {
            sppSubscriptionStats[hash2sppId[hash]].remainingToBeFulfilled = _subscriptionData.remainingToBeFulfilled.sub(amt);
        }
        return true;
    }

    function setcurrentTokenStats(bytes32 hash, uint256 amountGotten, uint256 amountGiven) public returns (bool success) {
        if (msg.sender != TradeEngineAddress) return false;
        uint256 sppID = hash2sppId[hash];
        currentTokenStats memory _tokenStats = tokenStats[sppID];
        tokenStats[sppID].amountGotten = _tokenStats.amountGotten.add(amountGotten);
        tokenStats[sppID].amountGiven = _tokenStats.amountGiven.add(amountGiven);
        emit SetCurrentTokenStats(sppID, amountGotten, amountGiven);
        return true;
    }

    function isActiveSpp(uint256 sppID) public view returns (bool res) {
        return sppSubscriptionStats[sppID].exists;
    }

    function getSppIdFromHash(bytes32 hash) public returns (uint256 sppID) {
        return hash2sppId[hash];
    }

    function getLatestOrderId() public view returns (uint256 oId) {
        return orderId;
    }

    function getRemainingToBeFulfilledByHash(bytes32 hash) public _tradeEngineOnly returns (uint256 res) {
        return sppSubscriptionStats[hash2sppId[hash]].remainingToBeFulfilled;
    }

    function getRemainingToBeFulfilledBySppID(uint256 sppID) public view returns (uint256 res) {
        return sppSubscriptionStats[sppID].remainingToBeFulfilled;
    }

    function getlistOfSubscriptions(address _from) public view returns (uint256[] arr) {
        return subList[_from].arr;
    }

    function getlistOfSppSubscriptions(address _from) public view returns (uint256[] arr) {
        return sppSubList[_from].arr;
    }

    function getcurrentTokenAmounts(uint256 sppID) public view returns (uint256[2] memory arr) {
        arr[0] = tokenStats[sppID].amountGotten;
        arr[1] = tokenStats[sppID].amountGiven;
        return arr;
    }

    function getTokenStats(uint256 sppID) public view returns (address[2] memory arr) {
        arr[0] = tokenStats[sppID].TokenToGet;
        arr[1] = tokenStats[sppID].TokenToGive;
        return arr;
    }

    function getLatestSppId() public view returns (uint256 sppId) {
        return sppID;
    }

    function getTimeRemainingToCharge(uint256 sppID) public view returns (uint256 time) {
        return ((sppSubscriptionStats[sppID].lastPaidAt +
            sppSubscriptionStats[sppID].period) - now);
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

    mapping(uint256 => currentTokenStats) tokenStats;
    mapping(address => listOfSppByAddress) sppSubList;
    mapping(address => listOfSubscriptions) subList;
    mapping(bytes32 => uint256) public hash2sppId;
    mapping(uint256 => uint256) public onGoing;
    mapping(uint256 => sppSubscribers) public sppSubscriptionStats;
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(uint256 => subscriptionstats) public subscriptiondata;

    struct subscriptionstats {
        uint256 value;
        uint256 period;
        uint256 lastPaidAt;
        address merchantAddress;
        address customerAddress;
        address tokenType;
        bool exists;
    }

    uint256 public orderId;
    address public owner;
    address private potentialAdmin;
    address public TradeEngineAddress;
    uint256 sppID;
    address public usdt;
    uint256 public usdtDecimal;
    uint256 public rateEthUsdt;
    uint256 nonce;
    address public feeAccount;
    uint256 public minPeriod;
}

contract CoinBNS is BNSToken {
    function() public {
        revert();
    }

    constructor() public {
        owner = msg.sender;
    }
}