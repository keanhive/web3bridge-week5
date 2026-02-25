// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultisigWallet {
    event Deposit(address indexed sender, uint256 amount);
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[3] public owners;
    mapping(address => bool) public isOwner;
    uint256 public constant REQUIRED = 2;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Tx exists");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Tx executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!confirmed[_txIndex][msg.sender], "Tx confirmed");
        _;
    }

    constructor(address[3] memory _owners) {
        require(_owners[0] != address(0) && _owners[1] != address(0) && _owners[2] != address(0), "Invalid owner");
        require(_owners[0] != _owners[1] && _owners[0] != _owners[2] && _owners[1] != _owners[2], "Duplicate owner");

        for (uint256 i = 0; i < 3; i++) {
            owners[i] = _owners[i];
            isOwner[_owners[i]] = true;
        }
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address _to, uint256 _value, bytes calldata _data)
    external
    onlyOwner
    returns (uint256 txIndex)
    {
        txIndex = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex)
    external
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmations += 1;
        confirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
    external
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.confirmations >= REQUIRED, "Need 2 signatures");
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Tx failed");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
    external
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    {
        require(confirmed[_txIndex][msg.sender], "Not confirmed");
        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmations -= 1;
        confirmed[_txIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() external view returns (address[3] memory) {
        return owners;
    }

    function getTransaction(uint256 _txIndex)
    external
    view
    returns (address to, uint256 value, bytes memory data, bool executed, uint256 confirmations)
    {
        Transaction storage transaction = transactions[_txIndex];
        return (transaction.to, transaction.value, transaction.data, transaction.executed, transaction.confirmations);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }
}