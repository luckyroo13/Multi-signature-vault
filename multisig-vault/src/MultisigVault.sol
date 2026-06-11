// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultisigVault {
    // ==========================================
    // 1. EVENTOS (Rastros en la blockchain)
    // ==========================================
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    // Aquí está el evento de la Fase 4 en su lugar correcto:
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    // ==========================================
    // 2. ESTADO BASE (Variables de almacenamiento)
    // ==========================================
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // ==========================================
    // 3. MODIFICADORES (Cadeneros de Seguridad)
    // ==========================================
    modifier onlyOwner() {
        require(isOwner[msg.sender], "No eres dueno de esta boveda");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "La transaccion no existe");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(
            !transactions[_txIndex].executed,
            "La transaccion ya se ejecuto"
        );
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(
            !isConfirmed[_txIndex][msg.sender],
            "Ya firmaste esta transaccion"
        );
        _;
    }

    // ==========================================
    // 4. CONSTRUCTOR (Inicialización)
    // ==========================================
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Se requieren duenos");
        require(
            _required > 0 && _required <= _owners.length,
            "Numero de firmas invalido"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Duenio invalido (direccion cero)");
            require(!isOwner[owner], "Duenio duplicado");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    // ==========================================
    // 5. FUNCIONES PRINCIPALES
    // ==========================================

    // FASE 1: Recibir dinero
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // FASE 2: Proponer Transacción
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    // FASE 3: Aprobar/Firmar Transacción
    function confirmTransaction(
        uint256 _txIndex
    )
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // FASE 4: Ejecutar Transacción (El Gatillo)
    function executeTransaction(
        uint256 _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= required,
            "No hay suficientes firmas"
        );

        // Patrón Checks-Effects-Interactions: Actualizamos estado ANTES de enviar dinero
        transaction.executed = true;

        // Enviamos el ETH
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );

        require(success, "Fallo al enviar la transaccion");

        // Emitimos (disparamos) el evento
        emit ExecuteTransaction(msg.sender, _txIndex);
    }
}
