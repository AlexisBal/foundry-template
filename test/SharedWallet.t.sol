// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/SharedWallet.sol";

contract SharedWalletTest is Test {
    SharedWallet public sharedWallet;

    function setUp() public {
        sharedWallet = new SharedWallet();
    }

    function testDeposit() public {
        /// @dev Deposit 1 Ether
        sharedWallet.deposit{value: 1 ether}();
        /// @dev Check that the contract balance is 1 Ether
        assertEq(address(sharedWallet).balance, 1 ether);
    }

    function testWithdrawETH() public {
        /// @dev Deposit 1 Ether
        sharedWallet.deposit{value: 1 ether}();
        /// @dev Check that the contract balance is 1 Ether
        assertEq(address(sharedWallet).balance, 1 ether);
        /// @dev Settle the allowance for the withdrawer
        sharedWallet.setAllowance(address(this), address(0), 1 ether);
        uint256 balanceBefore = address(this).balance;
        /// @dev Withdraw 1 Ether
        sharedWallet.withdrawETH(1 ether);
        uint256 balanceAfter = address(this).balance;
        /// @dev Check that the contract balance is 0 Ether
        assertEq(address(sharedWallet).balance, 0);
        /// @dev Check that the withdrawer balance is 1 Ether
        assertEq(balanceAfter - balanceBefore, 1 ether);
    }

    function testUserAllowedToWithdraw() public {
        /// @dev Deposit 10 Ether
        sharedWallet.deposit{value: 10 ether}();
        /// @dev Check that the contract balance is 10 Ether
        assertEq(address(sharedWallet).balance, 10 ether);
        /// @dev Settle the roles
        sharedWallet.grantRole(sharedWallet.WITHDRAWER_ROLE(), address(1));
        sharedWallet.grantRole(sharedWallet.WITHDRAWER_ROLE(), address(2));
        /// @dev Settle the allowances 
        sharedWallet.setAllowance(address(1), address(0), 1 ether);
        sharedWallet.setAllowance(address(3), address(0), 1 ether);
        /// @dev Change the caller to address(1)
        vm.startPrank(address(1));
        sharedWallet.withdrawETH(1 ether);
        assertEq(address(1).balance, 1 ether);
        /// @dev Change the caller to owner
        vm.stopPrank();
        /// @dev Change the caller to address(2)
        vm.startPrank(address(2));
        /// @dev Next line should fail
        vm.expectRevert();
        sharedWallet.withdrawETH(1 ether);
        /// @dev Change the caller to owner
        vm.stopPrank();
        /// @dev Change the caller to address(3)
        vm.startPrank(address(3));
        /// @dev Next line should fail
        vm.expectRevert();
        sharedWallet.withdrawETH(1 ether);

    }

    receive() external payable {}
}
