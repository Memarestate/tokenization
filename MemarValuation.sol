pragma solidity ^0.4.24;

//import 'openzeppelin-solIdity/contracts/token/ERC20/ERC20.sol';
import './MemarTokenization.sol';
// okay this can't be a contract in the same file... need to figrue it out'
// contract MemarTokenization {
//     function requestTokenization(bytes32 paymentId, uint256 disputedMEMTokens, address host, address guest) external;
//     function normTokenizationFee() external returns (uint256);
    
// }

contract MemarTransaction {
    
    ERC20 memToken;  //mem token address TODO
    address memTokenizationContractAddress;
    MemarTokenization memTOkenize;

    constructor (address memTokenContractAddress, address tokenizationAddress)
    public 
    {
        memTokenizationContractAddress = tokenizationAddress;
        memToken = ERC20(memTokenContractAddress);
        memTokenize = MemarTokenization(memTokenizationContractAddress);
    }
    
    function setTokenizationAddress(address tokenizationAddress) public {
        MemarTokenizationContractAddress = tokenizationAddress;
        memTokenize = MemarToeknization(memTokenizationContractAddress);
    }
    
    
    function sendTokenizationRequest (address guest, address host, uint256 tokenizeAmt, bytes32 PaymentId) public  {
        //memToken.mintFreeMEMTokens();
        disputeAmt = disputeAmt + memTokenize.normTokenizeFee();
        memToken.approve(memTokenizationContractAddress, tokenizeAmt);
        memTokenize.requestTokenization(PaymentId, tokenizeAmt, provider, investor);
        
     }
}

