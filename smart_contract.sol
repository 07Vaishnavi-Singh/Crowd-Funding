// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract CrowdFunding{

mapping(address=>uint) public contributors ;

 address public manager ;
 uint public target ;
 uint  public deadline;
 uint public minFund;
 uint  public noOfContributors; 
 uint public raisedAmount; // to compare afterwards with the target 
 
mapping(uint=> Request) public requests; // to maintain a log of all the requests 

uint public numRequest;

 struct Request{
     string reason;
    address payable receipient;
    uint amount;
    bool status;
    uint noOfVoters;
    mapping(address=> bool) votes; 
 }


modifier onlyManager{
require(msg.sender == manager,"Only manager can call this function ");
_;
}

constructor(uint _target,uint _deadline, uint _minFund){
    manager=msg.sender;
    target = _target;
    deadline= block.timestamp + _deadline;// to add  deadline to the unix timeline
    minFund=_minFund;
}

function sendEth() public payable{

 require(block.timestamp < deadline,"Sorry you are late " );
 require(msg.value >= minFund,"You need to fund atleast the minimum amount of fund" );
 require(manager!=msg.sender,"Manager cannot add funds");
 require(raisedAmount < target,"The target value has been raised");
 
 if(contributors[msg.sender]==0){
     noOfContributors++;
 }

 contributors[msg.sender]+=msg.value;
 raisedAmount+=msg.value;

}

function checkBalance() public view returns(uint){
 require(msg.sender==manager);
 return address(this).balance;
}

function refund() public {
    require(block.timestamp >  deadline );
    require(raisedAmount < target);
   address payable user = payable(msg.sender); // as user wants to get funded money back 
   user.transfer(contributors[msg.sender]); 
   contributors[msg.sender]=0;
}

function createRequest(string memory _reason ,address payable _receipient, uint _amount) public onlyManager {
 Request storage newRequest = requests[numRequest]; // storage is used whenever we use mapping inside struct 
 numRequest++;
newRequest.reason= _reason ;
newRequest.receipient= _receipient ;
newRequest.amount= _amount ;
newRequest.status= false ;
newRequest.noOfVoters= 0 ;
}

function voteRequest(uint _numRequest) public {
     require(contributors[msg.sender] != 0,"Only contributors can pull a request ");
    Request storage thisRequest = requests[_numRequest]; 
    require(thisRequest.votes[msg.sender]==false, "You can only vote once");
    thisRequest.votes[msg.sender]= true;
    thisRequest.noOfVoters ++;
}

function makepayment(uint _requestNumber ) public onlyManager{
    require(raisedAmount > target );
    Request storage thisRequest = requests[_requestNumber];
    require(thisRequest.status==false,"The request has beeen completed");
    require(thisRequest.noOfVoters > noOfContributors/2);
    thisRequest.receipient.transfer(thisRequest.amount);
    thisRequest.status=true;
}   

}
