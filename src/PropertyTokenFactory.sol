// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MyPropertyToken.sol";

contract PropertyTokenFactory {
    struct PropertyInfo {
        string name;
        address tokenAddress;
    }

    PropertyInfo[] public properties;
    mapping(string => address) public nameToToken;

    event PropertyCreated(string name, address tokenAddress);

    function createPropertyToken(
        string memory _name,
        string memory _symbol,
        string memory _propertyName,
        uint256 _initialSupply
    ) public {
        MyPropertyToken token = new MyPropertyToken(
            _name,
            _symbol,
            _propertyName,
            _initialSupply,
            msg.sender
        );

        properties.push(PropertyInfo(_propertyName, address(token)));
        nameToToken[_propertyName] = address(token);

        emit PropertyCreated(_propertyName, address(token));
    }

    function getAllProperties() public view returns (PropertyInfo[] memory) {
        return properties;
    }
}