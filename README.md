# bns-token


BNS token contains quite a few features which will be discussed below one by one. 

BNS implements freezing of tokens upon their first issuance to a user. A fixed amount of the frozen tokens is released every time period.
A service subscription feature which allows a customer to subscribe to a service provided by some merchant and a recurring payment will be made every time period automatically, without the intervention of the customer.
Another feature of BNS token is that it has Bitcoin SPP(systematic purchase plan) and SWP(systematic withdrawal plan) built into it.


# FREEZING OF TOKENS

There are two functions which allow the contract owner to issue the tokens to some address, “transfer” and “issueMulti”. These functions can only be called by the owner(see modifier _ownerOnly). “issueMulti” is a function which does the same thing as “transfer”, only for a large number of addresses at once. While issuing the tokens, a part of them is frozen till “lock_till” time. “per_tp_release_amt” amount of frozen tokens are released every “time_period”. All these data are stored in a mapping called “userdata” which maps address to a struct called userstats.


# SUBSCRIPTION AND RECURRING PAYMENTS

The “subscribe” function allows a customer with address “customerAddress” to give permission to a merchant with “merchantAddress” to “charge” the customer a fixed amount of token every time period. An “orderId” variable is used a key in the mapping “subscriptiondata”. “transferInternal” is an internal function which can be called only through the “charge” function which in turn is callable only by the contract owner.


SPP and SWP

A customer can start an SPP where he/she can buy BTC with a fixed amount of some stable token(USDT in this case) every day/week/month/any time period the customer chooses. We have two new coins for the testing purposes. BNSS is the USDT backed coin and BNSB is the BTC backed. A fixed amount of BNSS will be sold every time period to buy BNSB once the user has started a SPP. Reverse of this flow would be called SWP. When “chargeSpp” is called, an order is placed on behalf of the customer by the contract. 

The order placing and fulfillment flow is taken care by the TradeEngine contract. It is basically a smart contract for implementing decentralized exchange. “Order” function is used to place an order, “trade” is used to fulfill it, “tradebalances” handles the updation of balances (with fee charging as well) upon successful trade.

# SPP/SWP FLOW

STEP 1.  First step is to set the contract addresses in bns.sol and TradeEngine.sol by using the functions “setbnsAddress” and “setTradeEngineAddress”. This will allow fluid external calls.

STEP 2. Both the order placer and the trader first need to deposit their token onto the TradeEngine contract. Token balances will be stored in “tokens” mapping.

STEP 3. Customers subscribe to SPP/SWP.

STEP 4. bns contract owner calls “chargeSpp” for a sppID which places a new order in TradeEngine(through the orderBNS function) on behalf of the customer of that sppID. 

STEP 5. A trader comes in and fulfills the placed order. He/She might fulfill it fully or partially, all that is handled by using “remainingToBeFulfilled”.

