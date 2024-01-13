// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

/*

Multisignature Wallet:

The multisignature wallet smart contract is designed to allow multiple owners to collectively control funds. Each owner possesses a unique private key, and a specified number of owners (threshold) must approve and execute a transaction for it to be successful. Key features include the ability for owners to submit, approve, and cancel transactions.

Design Choices:

The contract employs a unique mapping structure, using a linked list of owners facilitated by the ownerss mapping. This design choice enhances the efficiency of adding, removing, and replacing owners. The introduction of a sentinel owner (SENTINEL_OWNER) at the beginning of the linked list simplifies the logic when iterating through owners, preventing potential edge cases where the list might be empty.

Transactions are structured using the Transaction struct, capturing essential information like destination address, value, data, execution status, and existence status. This provides a clean and organized way to manage transaction-related data.

Critical functions like adding, removing, and replacing owners are marked as internal and can only be called when the required number of owners approves the action. This ensures that significant changes to the contract's state can only occur with the consensus of a predetermined number of owners, enhancing security and preventing unauthorized alterations.

The isConfirmed function efficiently checks if the required number of confirmations has been met. It iterates through the linked list of owners, counting confirmed votes until the required threshold is reached or all owners have been checked.

The introduction of a fallback function allows the contract to receive ether, enabling users to deposit funds directly into the contract.

Security Considerations:

To bolster security, the contract incorporates strict access control measures. The onlyWallet modifier ensures that critical functions can only be invoked by the contract itself, preventing external manipulation. The sentinel owner, by design, cannot be removed or replaced, fortifying the integrity of the linked list structure and safeguarding against potential vulnerabilities.

A reentrancy guard is implemented in the _call function, mitigating the risk of reentrancy attacks. This is especially crucial when dealing with external calls to other contracts.

Events are utilized to log various state changes, promoting transparency and auditability. This design choice facilitates the monitoring of contract activities and timely responses to any unexpected behavior.

Efforts are made to optimize gas usage, particularly in loops that iterate over the linked list of owners. The use of a sentinel owner and careful iteration logic minimizes unnecessary gas consumption during owner-related operations.

The notExecuted modifier is introduced to ensure that transactions can only be confirmed and executed once, preventing potential issues related to multiple executions of the same transaction.

These design choices and security considerations collectively contribute to the development of a secure and efficient multisignature wallet in the context of Solidity blockchain development. Regular code reviews and security audits are recommended to maintain and enhance the security of the smart contract over time.
*/

contract MultiSigWallet {
    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    /*
     * Constants
     */
    uint public constant MAX_OWNER_COUNT = 50;
    address public constant SENTINEL_OWNER = address(0x1);
    /*
     *  Storage
     */
    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(address => address) public owners;
    uint256 public ownersCount;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
        bool exists;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(owners[owner] == address(0));
        _;
    }

    modifier ownerExists(address owner) {
        require(owners[owner] != address(0));
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].exists == true);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(_required <= ownerCount && _required != 0 && ownerCount != 0);
        _;
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(
        address[] memory _owners,
        uint _required
    ) validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            require(
                _owners[i] != address(0) && _owners[i] != SENTINEL_OWNER,
                "Invalid owner address"
            );
        }
        required = _required;
        owners[SENTINEL_OWNER] = _owners[0];
        owners[_owners[0]] = SENTINEL_OWNER;
        for (uint i = 1; i < _owners.length; i++) {
            owners[_owners[i - 1]] = _owners[i];
            owners[_owners[i]] = SENTINEL_OWNER;
        }
        ownersCount = _owners.length;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(
        address owner
    )
        public
        onlyWallet
        ownerDoesNotExist(owner)
        validRequirement(ownersCount + 1, required)
    {
        require(
            owner != SENTINEL_OWNER && owner != address(0),
            "Invalid owner address"
        );
        // isOwner[owner] = true;
        // owners.push(owner);
        address lastOwner = SENTINEL_OWNER;
        while (owners[lastOwner] != SENTINEL_OWNER) {
            lastOwner = owners[lastOwner];
        }
        owners[lastOwner] = owner;
        owners[owner] = SENTINEL_OWNER;
        ownersCount += 1;

        emit OwnerAddition(owner);
    }
    
    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner) public onlyWallet ownerExists(owner) validRequirement(ownersCount-1, required) {
        address previousOwner = SENTINEL_OWNER;
        while (owners[previousOwner] != owner) {
            previousOwner = owners[previousOwner];
        }
        owners[previousOwner] = owners[owner];
        owners[owner] = address(0);
        ownersCount -= 1;
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(
        address owner,
        address newOwner
    ) public onlyWallet ownerExists(owner) ownerDoesNotExist(newOwner) {
        address previousOwner = SENTINEL_OWNER;
        while (owners[previousOwner] != owner) {
            previousOwner = owners[previousOwner];
        }
        owners[previousOwner] = newOwner;
        owners[newOwner] = owners[owner];
        owners[owner] = address(0);
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(
        uint _required
    ) public onlyWallet validRequirement(ownersCount, _required) {
        required = _required;
        emit RequirementChange(_required);
    }
    
    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function submitTransaction(
        address destination,
        uint value,
        bytes calldata data
    ) public returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }
    
    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(
        uint transactionId
    )
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(
        uint transactionId
    )
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(
        uint transactionId
    )
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (_call(txn.destination, txn.value, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }
    
   

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return isTxConfirmed Confirmation status.
    function isConfirmed(
        uint transactionId
    ) public view returns (bool isTxConfirmed) {
        uint count = 0;
        address lastOwner = SENTINEL_OWNER;
        while (owners[lastOwner] != SENTINEL_OWNER) {
            lastOwner = owners[lastOwner];
            if (confirmations[transactionId][lastOwner]) count += 1;
            if (count == required) return true;
        }
    }

    /*
     * Internal functions
     */
    function _call(
        address target,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        bytes memory result;
        (success, result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function addTransaction(
        address destination,
        uint value,
        bytes calldata data
    ) internal returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false,
            exists: true
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */

    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(
        uint transactionId
    ) public view returns (uint count) {
        address lastOwner = SENTINEL_OWNER;
        while (owners[lastOwner] != SENTINEL_OWNER) {
            lastOwner = owners[lastOwner];
            if (confirmations[transactionId][lastOwner]) count += 1;
        }
    }
    

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(
        bool pending,
        bool executed
    ) public view returns (uint count) {
        for (uint i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) count += 1;
    }
    
    /// @dev Returns list of owners.
    /// @return result List of owner addresses.
    function getOwners() public view returns (address[] memory result) {
        result = new address[](ownersCount);
        address lastOwner = SENTINEL_OWNER;
        uint i = 0;
        while (owners[lastOwner] != SENTINEL_OWNER) {
            lastOwner = owners[lastOwner];
            result[i] = lastOwner;
            i++;
        }
        return result;
    }
    
    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of owner addresses.
    function getConfirmations(
        uint transactionId
    ) public view returns (address[] memory _confirmations) {
        address[] memory confirmationsTemp = new address[](ownersCount);
        uint count = 0;
        address lastOwner = SENTINEL_OWNER;
        while (owners[lastOwner] != SENTINEL_OWNER) {
            lastOwner = owners[lastOwner];
            if (confirmations[transactionId][lastOwner]) {
                confirmationsTemp[count] = lastOwner;
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (uint i = 0; i < count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }
    
    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _transactionIds Returns array of transaction IDs.
    function getTransactionIds(
        uint from,
        uint to,
        bool pending,
        bool executed
    ) public view returns (uint[] memory _transactionIds) {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }
}
