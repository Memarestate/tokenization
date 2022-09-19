pragma solidity ^0.8.1;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Tokenization {
    function requestTokenization(
        bytes32 id,
        uint256 tokens,
        address supplier,
        address purchaser
    )
        external;
}

contract TestTokenization is RealEstate, Ownable {
    event Tokenize(
        bytes32 id,
        uint256 tokens,
        address supplier,
        address purchaser
    );

    function requestTokenization(
        bytes32 id,
        uint256 tokens,
        address supplier,
        address purchaser
    )
        external
    {
        emit Tokenize(id, tokens, supplier, purchaser);
    }
}
