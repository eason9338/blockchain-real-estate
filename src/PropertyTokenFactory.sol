// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MyPropertyToken.sol"; // 引入自定義代幣合約
import "./PropertyDAO.sol";     // 引入 DAO 合約

contract PropertyTokenFactory {
    struct PropertyInfo {
        string name;
        address tokenAddress;
        address daoAddress;
    }

    PropertyInfo[] public properties;
    mapping(string => address) public nameToToken;
    mapping(address => address) public tokenToDAO;

    event PropertyCreated(string name, address tokenAddress, address daoAddress);

    function createPropertyToken(
        string memory _name,
        string memory _symbol,
        string memory _propertyName,
        uint256 _initialSupply
    ) public {
        // 1️⃣ 部署新的 ERC20 代幣合約
        MyPropertyToken token = new MyPropertyToken(
            _name,
            _symbol,
            _propertyName,
            _initialSupply,
            msg.sender
        );

        // 2️⃣ 部署綁定的 DAO 合約
        PropertyDAO dao = new PropertyDAO(address(token), msg.sender);

        // 3️⃣ 記錄資訊
        properties.push(PropertyInfo(_propertyName, address(token), address(dao)));
        nameToToken[_propertyName] = address(token);
        tokenToDAO[address(token)] = address(dao);

        emit PropertyCreated(_propertyName, address(token), address(dao));
    }

    function getAllProperties() public view returns (PropertyInfo[] memory) {
        return properties;
    }

    function getDAOByToken(address token) public view returns (address) {
        return tokenToDAO[token];
    }
}
