// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MultisigVault} from "../src/MultisigVault.sol";

contract MultisigVaultTest is Test {
    MultisigVault vault;

    // Creamos 4 cuentas falsas para nuestra simulación
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address hacker = address(0x4);

    // --- setUp: Se ejecuta ANTES de cada test ---
    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vault = new MultisigVault(owners, 2);
    }

    // --- test_Deposit: Nuestra primera prueba ---
    function test_Deposit() public {
        vm.deal(owner1, 10 ether);
        vm.prank(owner1);
        (bool success, ) = address(vault).call{value: 5 ether}("");

        assertTrue(success, "El deposito fallo");
        assertEq(
            address(vault).balance,
            5 ether,
            "El balance de la boveda deberia ser 5 ETH"
        );
    }

    // --- test_FullTransactionFlow: El ciclo completo ---
    function test_FullTransactionFlow() public {
        vm.deal(address(vault), 10 ether);

        uint256 amountToSend = 3 ether;
        uint256 owner3BalanceAntes = owner3.balance;

        // FASE 2: Proponer
        vm.prank(owner1);
        vault.submitTransaction(owner3, amountToSend, "");

        // FASE 3: Firmar (Dueño 2 y Dueño 1)
        vm.prank(owner2);
        vault.confirmTransaction(0);

        vm.prank(owner1);
        vault.confirmTransaction(0);

        // FASE 4: Ejecutar
        vm.prank(owner1);
        vault.executeTransaction(0);

        // VERIFICACIÓN MATEMÁTICA
        assertEq(
            owner3.balance,
            owner3BalanceAntes + amountToSend,
            "Owner 3 no recibio el dinero"
        );
        assertEq(
            address(vault).balance,
            7 ether,
            "La boveda deberia tener 7 ETH"
        );
    }

    // --- test_RevertIf_HackerTriesToSubmit: Seguridad pura ---
    function test_RevertIf_HackerTriesToSubmit() public {
        vm.prank(hacker);
        vm.expectRevert("No eres dueno de esta boveda");
        vault.submitTransaction(hacker, 1 ether, "");
    }
}
