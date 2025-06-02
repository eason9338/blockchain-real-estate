// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyPropertyToken is ERC20, Ownable {
    address public propertyManager;
    string public propertyName;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _propertyName,
        uint256 _initialSupply,
        address _creator
    ) ERC20(_name, _symbol) Ownable(_creator) {  // 這裡加入 Ownable(_creator)
        propertyName = _propertyName;
        propertyManager = _creator;
        _mint(_creator, _initialSupply);
        // 不需要 transferOwnership，因為已經在 Ownable(_creator) 設定了擁有者
    }

    function setPropertyManager(address newManager) public onlyOwner {
        propertyManager = newManager;
    }
}