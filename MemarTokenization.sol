/************************
 * Version 0.1 of Memar RealEstate Tokenization
 * WARNING: byte code is real close to ganache limit
 * a few more lines and it won't port over but if you
 * use remix you have some room to spare.  There must be a
 * optmizer for bytecode size somewhere
 * 
 * Not created for production
 * Not fully unit tested
 * No audits for hacking have 
 been done
 * ***********************/


pragma solidity ^0.8.0;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';


contract BaseModifiers is Ownable{
    bool activated_;
    
    function activated() 
        public
        view
        returns (bool)
    {
        return activated_;
    }
    
    modifier isActivated() {
        require(activated_ == true, "its not ready yet"); 
        _;
    }

    function activateContract() public onlyOwner {
        activated_ = true;
    }

    function deactivateContract() public onlyOwner {
        activated_ = false;
    }

}
contract MemarModifiers is BaseModifiers {
    mapping (address => bool) public whiteListedContracts;

    function addContractAddress(address _contractAddress) onlyOwner external {
        require(whiteListedContracts[_contractAddress]==false, "contract addres already added");
        whiteListedContracts[_contractAddress]=true;
    }
    function removeContractAddress(address _contractAddress) onlyOwner external {
        require (_contractAddress != 0, "contract address can't be 0");
        require (whiteListedContracts[_contractAddress] != false, "must be a valid address");
        delete(whiteListedContracts[_contractAddress]);
    }

    modifier isNotContract() {
        address _addr = msg.sender;
        require (_addr == tx.origin);
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry only white listed contracts allowed");
        _;
    }
    
    modifier isWhitelistedContract() {
        address _addr = msg.sender;
        require(whiteListedContracts[_addr]==true);
        _;
    }
}

contract MemarRealEstateValue {
    
    event MinerBanned
    (
        uint256 minerId, //the unique Ids of the tokenization requested
        uint256 timestamp //timestamp of request
    );

    event MinerApproved
    (
        uint256 minerId, //the unique Ids of the tokenization requested
        uint256 timestamp //timestamp of request
    );


    // fired whenever an tokenization is requested
    event TokenRequested
    (
        uint256 tokenizationId, //the unique Ids of the tokenization requested
        bytes32 paymentId, //payment Ids are byte32s, reservation Id might be different
        uint256 timestamp, //timestamp of request
        uint256 minTime, //min timetimestamp to wait for when miners can start to try and tokenize
        uint256 maxTime, //maximum timestamp to wait until before defaulting to default property providers
        uint256 memTokensTokenize, //amount of mem tokens in tokenization
        uint256 memTokensTokenization //amount of mem tokens paid for memar to occur
    );
    
    event MinerStartedMining
    (
        uint256 tokenizationId, //The unique id of miner
        uint256 minerIndexId, //The index of the miner array (really a set) they are in
        uint256 stake, //the stake the miner started mining with
        uint256 timestamp //timestamp of request
    );
    
    event MinerFailedStartedMining
    (
        uint256 tokenizationId, //The unique id of miner
        bytes32 errorMessage,
        uint256 stake, //the stake the miner started mining with
        uint256 timestamp //timestamp of request
    );

    event MinerStoppedMining
    (
        uint256 tokenizationId, //The unique id of miner
        uint256 stake, //the stake the miner started mining with
        uint256 timestamp //timestamp of request
    );

    event TokenizationJobTriggered
    (
        uint256 tokenizationJobId, //The unique id of job triggered
        address triggermanAddress, //the address of the person who triggered the event
        uint256 path, //the path that the trigger took
        uint256 timestamp //timestamp of request
    );
    
    event TokenizationRequestSubmitted
    (
        uint256 tokenizationId, //The unique id of property owner
        uint256 ValuationSubmitted, //the path that the trigger took
        uint256 timestamp //timestamp of request
    );
    // fired when not enough miners are present to start arbitration process
    event TokenizationDelayed
    (
        uint256 errorCode, //1 = not enough miners
        uint256 tokenizationId, //the unique Id of the valuation requested
        bytes32 paymentId, //payment Ids are byte32s, reservation Id might be different
        uint256 timestamp //timestamp
    );

    // fired when an tokenization is completed
    event ValueCompleted
    (
        uint256 valuationId, //the unique Id of the tokenization requested
        //maybe put in who voted for what in here too?
        uint256 voteResult, // percent 0 - 100 awarded to investor, rest awarded to owner
        bytes32 paymentId, //payment Ids are byte32s, reservation Id might be different
        uint256 timestamp //timestamp of vote
    );
    
    event ValuationPaid
    (
        uint256 ProviderId, //id of provider
        uint256 vote, // vote casted
        uint256 amountPaid, //amount paid
        uint256 timestamp //timestamp of vote
    );

    event valuation completed
    (
        uint256 investorId, //id of investor
        uint256 voteId, // the unique id of the vote they needed to do but failed to do
        uint256 memTokenTaken, //amount paid
        uint256 memTokenStaked, //amount paid
        uint256 timestamp //timestamp of vote
    );

    
}

contract MemarTokenizationStructs {
    struct TokenizationJob {
        uint256 tokenizationId; //if this was an appeal, this is the Id of the tokenization it came from
        bytes32 paymentId; //payment Ids are byte32s, reservation Id might be different
        uint256 timestamp; //timestamp of request
        uint256 minMinerTime; //min timetimestamp to wait for when miners can start to try and arbitrate
        uint256 maxMinerTime; //maximum timestamp to wait until before defaulting to default evaluator
        uint256 appealTimelimit; //maximum time allowed for appeal
        uint256 memTokensValuationFee; //amount of mem tokens paid for tokenization to occur
        uint256 [] provideReqIds;
        uint256 disputedAmountOfMEMTokens;
        address host;
        address guest; 
    }
    
    enum EvaluatorAccessState {
        PENDING_APPROVAL,      // can trigger but cannot mine
        APPROVED,    // can trigger and can mine
        BANNED //can trigger but cannot mine
    }

    //try to use up 256 bits
    struct Evaluator {
        EvaluatorAccessState accessState;//8bit int, holds info if they can mine or trigger
        address minerAddress; 
        uint256 miningArrayIndex;
        uint256 currentMEMTokenStake;
        uint256 valuationsCompleted; //maybe put this in reputation api
        uint256 valuationsRequested;  //maybe put this in reputation api
        uint256 [] evaluatorIds;
    }
    
    enum VoteState {
        NOT_ASSIGNED_TO_EVALUATOR, //assigned to a job but not yet assigned to a miner / evaluator yet
        PENDING_VOTE, //Evaluator hasn't voted yet
        VOTE_COMPLETE, //Evaluator has voted
        PENALIZED_NO_VOTE, //Evaluator failed to vote by min mining time and was penalized for it
        VOTE_PAID //Evaluator voted and was paid for it
    }

    struct EvaluatorVote {
        VoteState state; //0 hasn't voted, 1 has voted, 2 penealized for not voting (NOTE: since we have extra bits, why not)
        uint8 vote;//0 by default
        uint256 valuationJobId;
        uint256 evaluatorId;
    }
    
    struct MinerTicketHolder {
        uint256 miningId;
        uint256 numLottoTickets;
    }
}

contract MemarTokenization is MemarTokenizationEvents, MemarModifiers, MemarTokenizationStructs {
    using SafeMath for uint256;

    uint8 memTokenPenality = 100; //0-100% pentality for Evaluator's staked mem tokens if submission isn't completed by max time
    uint8 activeMinerPayPercentage = 100; //After the triggerman get's paid, this is the percentage of mem tokens that are left over that get distributed among the evaluators
    uint8 percentPenTokensToFee = 100; //percent of mem tokens taken from miners who didn't vote put into miners fee.  rest just lives in contract until owner pulls it out
    
    uint8 percentAppealFeeToDisputeAmount = 0; //percent of mem tokens after we subtract tokenization fee to be put into dispute amount for provider/ investor, the rest goes to owner of contract

    uint8 [] triggermanPayMEMTokenAmount = [2,3,3,3,3,3];  //how much the triggerman gets paid.  each element in the array is a pay path
    uint8 [] percentDisputedChoices = [0,25,50,75,100];//0,25,50,75,100 in whitepaper.  percent of mem tokens of the disputed amount to be distributed to the winner.  This is the vote choices

    uint8 nonce = 0; //used for random number generation
    uint8 appealMultCost = 2; //multiplier of previous appeal cost so they appeal less
    uint8 evaluatorsPerJob = 5;

    //todo figure out gas price of executing everything, write up code that gets current eth price and current mem price then figures out a correct arb fee or static?
    uint256 public normValFee = 1110000; //fee we charge to do valuations

    uint256 public minMiningStake = 1000; //min number of mem tokens needed to stake for miners
    uint256 minMinerTime = 1 days; //min time to wait before miners can be selected as Evaluators
    uint256 maxMinerTime = 5 days; //max time to wait before going to default Evaluators
    uint256 appealTime = 3 days; //max time allowed for users to appeal decisions

    Evaluators [] public existingArbiters;//requirement is existing Evaluators index 0 needs to be taken in constuctor because mapping returns 0 if not there
    MinerTicketHolder [] public evaluatorsMining; //we can't make this into a view because the contract that modifies data will need this info, read costs like 5k, write is 20k
    TokenizationJob [] public tokenizationJobs;
    EvaluzatorVote [] public evaluatorVotes;

    mapping (address => uint256) public addressToMinerId;
    uint256 [] public jobsInProgress; //when an tokenization job comes in, the Id is in here till it is completed or appealed
    mapping (bytes32 => uint256[]) public paymentIdToJobIds;

    
    address memTokenContractAddress;
    BEP20 memToken;  
    
    
////////
//OWNER FUNCTIONS 
////////
    /**
     * @dev default function, unsure about this at the moment, maybe disable
     *  -functionhash- unknown yet
     */
    function () public payable {
        revert();
    }


    /**
     * @dev constructor, adds default values for everything and adds in
     *    a dummy var for our pointers that maps can go to.  A map value without
     *    a key produces a value of 0, so as an extra safeguard, I put in dummy
     *    values at location 0 so if there is a problem it's not as bad
     *  -functionhash- unknown yet
     */
    constructor(address memTokenAddress) 
    public 
    {
        memTokenContractAddress = memTokenAddress;
        memToken = BEP20(memTokenContractAddress);

        
        Evaluator memory dummyEvaulator = Evaluator({
            accessState:EvaluatorAccessState.BANNED,
            minerAddress:0x0,
            currentMEMTokenStake:0, 
            arbitrationsCompleted:0, 
            arbitrationsAppealed:0, 
            miningArrayIndex:0,
            arbiterVoteIds:new uint256[](0)
        });
        existingEvaluators.push(dummyEvaluator);
        
        
        
        EvaluationJob memory dummyEvaluatorJob = valuationJob({
            valuationId:0,
            paymentId:"dummyJob",
            timestamp:0,
            minMinerTime:0, 
            maxMinerTime:0,
            appealTimelimit:0,
            memTokensValuationFee:0,
            arbiterVoteIds:new uint256[](evaluatorsPerJob),
            disputedAmountOfMEMTokens:0,
            host:0x0,
            guest:0x0
        });
        valuationJobs.push(dummyEvaluatorJob);
        
        jobsInProgress.push(0); //not really needed but lets make it consistant

        
        //not really needed but better safe then sorry if someone decides to add in a mapping to this array    
        EvaluatorVote memory dummyEvaluatorVote = EvaluatorVote({
            state:VoteState.PENDING_VOTE,
            arbitrationJobId:0,
            vote:0,
            arbiterId:0
        });
        evalVotes.push(dummyEvaluatorVote);



        MinerTicketHolder memory curTickets = MinerTicketHolder({
            miningId:0, 
            numLottoTickets:0
        });
        evaluatorsMining.push(curTickets);


    }

    /**
     * @dev owner of the contract has to approve all miners before they can vote
     *  -functionhash- unknown yet
     * @param evalId valuationId of the evaluator / miner
     */
    function approveMiner(uint256 arbId)
        onlyOwner()
        external
    {
        require(arbId < existingArbiters.length, "no evaluator by that number exists");
        Evaluator storage curMiner = existingEvaluator[evalId];
        curMiner.accessState = EvaluatorAccessState.APPROVED;
//        emit MinerApproved(arbId, now);
    }

    /**
     * @dev take a ban a miner from voting again
     *  -functionhash- unknown yet
     * @param arbId valuationId of the arbiter / miner
     */
    function banMiner(uint256 arbId)
        onlyOwner()
        external
    {
        require(arbId < existingArbiters.length, "no evalutor by that number exists");
        Evaluator storage curMiner = existingEvaluator[evalId];
        curMiner.accessState = EvaluatorAccessState.BANNED;
        
        uint index = curMiner.miningArrayIndex;
        if (index >= 1) {
            removeMinerFromQueue(index);
            curMiner.miningArrayIndex = 0;
            //they could still be voting so we don't want to return their stake in case we need to penalize them later
            //require(memToken.transfer(curMiner.minerAddress, curMiner.currentMEMokenStake), "transfer to miner stake failed");
            //curMiner.currentMEMTokenStake = 0;
        }
//        emit MinerBanned(arbId, now);
    }

    