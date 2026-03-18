// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Vendored from https://github.com/Reactive-Network/reactive-lib

interface IPayable {
    receive() external payable;
    function debt(address _contract) external view returns (uint256);
}

interface IPayer {
    function pay(uint256 amount) external;
    receive() external payable;
}

abstract contract AbstractPayer is IPayer {
    IPayable internal vendor;
    mapping(address => bool) internal senders;

    receive() virtual external payable {}

    modifier authorizedSenderOnly() {
        require(senders[msg.sender], 'Authorized sender only');
        _;
    }

    function pay(uint256 amount) external authorizedSenderOnly {
        _pay(payable(msg.sender), amount);
    }

    function coverDebt() external {
        uint256 amount = vendor.debt(address(this));
        _pay(payable(vendor), amount);
    }

    function _pay(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Insufficient funds');
        if (amount > 0) {
            (bool success,) = recipient.call{value: amount}(new bytes(0));
            require(success, 'Transfer failed');
        }
    }

    function addAuthorizedSender(address sender) internal {
        senders[sender] = true;
    }

    function removeAuthorizedSender(address sender) internal {
        senders[sender] = false;
    }
}

abstract contract AbstractCallback is AbstractPayer {
    address internal rvm_id;

    constructor(address _callback_sender) {
        rvm_id = msg.sender;
        vendor = IPayable(payable(_callback_sender));
        addAuthorizedSender(_callback_sender);
    }

    modifier rvmIdOnly(address _rvm_id) {
        require(rvm_id == _rvm_id, 'Authorized RVM ID only');
        _;
    }
}
