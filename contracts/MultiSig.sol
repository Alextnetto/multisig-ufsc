//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

contract MultiSig {
    mapping(address => bool) public isSigner;
    uint8 public minRequiredSignatures;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint8 numSignatures;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isApproved;

    modifier onlySigner() {
        require(isSigner[msg.sender], "only signer can call this function");
        _;
    }

    modifier transactionExists(uint256 _transactionId) {
        require(
            _transactionId < transactions.length,
            "transaction does not exist"
        );
        _;
    }

    modifier notExecutedTransaction(uint256 _transactionId) {
        require(
            !transactions[_transactionId].executed,
            "transaction already executed"
        );
        _;
    }

    modifier notApprovedTransaction(uint256 _transactionId) {
        require(
            !isApproved[_transactionId][msg.sender],
            "transaction already confirmed"
        );
        _;
    }

    constructor(address[] memory _signers, uint8 _minRequiredSignatures) {
        require(_signers.length > 0, "signers required");
        require(
            _minRequiredSignatures > 0,
            "require minimum signatures to approve transactions"
        );
        require(
            _minRequiredSignatures <= _signers.length,
            "number of signers need to be > than min required signatures"
        );

        for (uint256 i; i < _signers.length; i++) {
            address signer = _signers[i];

            require(signer != address(0), "signer address cant be 0x0");
            require(!isSigner[signer], "signer must be unique");

            isSigner[signer] = true;
        }

        minRequiredSignatures = _minRequiredSignatures;
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlySigner {
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numSignatures: 0
            })
        );
    }

    function approveTransaction(uint256 _transactionId)
        external
        onlySigner
        transactionExists(_transactionId)
        notExecutedTransaction(_transactionId)
        notApprovedTransaction(_transactionId)
    {
        Transaction storage transaction = transactions[_transactionId];
        transaction.numSignatures += 1;

        isApproved[_transactionId][msg.sender] = true;
    }

    function executeTransaction(uint256 _transactionId)
        external
        onlySigner
        transactionExists(_transactionId)
        notExecutedTransaction(_transactionId)
    {
        Transaction storage transaction = transactions[_transactionId];
        require(
            transaction.numSignatures >= minRequiredSignatures,
            "need more signatures to execute transaction"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "transaction failed");
    }
}
