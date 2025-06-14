// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PropertyTokenFactory.sol";
import "../src/MyPropertyToken.sol";
import "../src/PropertyDAO.sol";
import "../src/PropertyMarketplace.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // Step 1：部署 Factory
        PropertyTokenFactory factory = new PropertyTokenFactory();
        console.log("Factory deployed at:", address(factory));

        // Step 2：透過 Factory 建立多個房產代幣用於測試
        // 第一個房產代幣
        factory.createPropertyToken(
            "Taipei Token",
            "TPT",
            "Taipei Rd. No. 101",
            1000 * 10**18 // 使用 18 位小數的表示方式
        );
        
        // 添加更多測試用房產代幣
        factory.createPropertyToken(
            "New Taipei Token",
            "NPT",
            "New Taipei City, Banqiao District",
            2000 * 10**18
        );
        
        factory.createPropertyToken(
            "Taichung Token",
            "TCT",
            "Taichung City, West District",
            1500 * 10**18
        );

        // Step 3：取得所有房產代幣的地址
        PropertyTokenFactory.PropertyInfo[] memory all = factory.getAllProperties();
        address firstTokenAddr = all[0].tokenAddress;
        console.log("First Property Token deployed at:", firstTokenAddr);
        console.log("Second Property Token deployed at:", all[1].tokenAddress);
        console.log("Third Property Token deployed at:", all[2].tokenAddress);

        // Step 4：部署對應的 DAO 合約（針對第一個代幣）
        PropertyDAO dao = new PropertyDAO(firstTokenAddr, deployer);
        console.log("PropertyDAO deployed at:", address(dao));

        // Step 5：部署市場合約
        PropertyMarketplace marketplace = new PropertyMarketplace();
        console.log("PropertyMarketplace deployed at:", address(marketplace));
        
        // Step 6：為測試賬戶初始化代幣
        // 獲取每個代幣合約的實例
        MyPropertyToken token1 = MyPropertyToken(all[0].tokenAddress);
        MyPropertyToken token2 = MyPropertyToken(all[1].tokenAddress);
        MyPropertyToken token3 = MyPropertyToken(all[2].tokenAddress);
        
        // 設置一些測試用的地址（假設這些是您測試時用的錢包地址）
        address testUser1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // 請換成您自己的測試地址
        address testUser2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // 請換成您自己的測試地址
        
        // 轉移一些代幣給測試用戶（從部署者帳戶轉出）
        token1.transfer(testUser1, 200 * 10**18);
        token1.transfer(testUser2, 100 * 10**18);
        
        token2.transfer(testUser1, 300 * 10**18);
        token2.transfer(testUser2, 200 * 10**18);
        
        token3.transfer(testUser1, 150 * 10**18);
        token3.transfer(testUser2, 250 * 10**18);
        
        // Step 7：在市場上創建一些初始代幣掛單
        // 批准市場合約可以轉移代幣
        token1.approve(address(marketplace), 50 * 10**18);
        token2.approve(address(marketplace), 100 * 10**18);
        token3.approve(address(marketplace), 75 * 10**18);
        
        // 在市場上創建掛單
        marketplace.createListing(address(token1), 50 * 10**18, 0.01 ether); // 每代幣 0.01 ETH
        marketplace.createListing(address(token2), 100 * 10**18, 0.015 ether); // 每代幣 0.015 ETH
        marketplace.createListing(address(token3), 75 * 10**18, 0.02 ether); // 每代幣 0.02 ETH
        
        console.log("Initialization completed: tokens distributed and marketplace listings created");

        vm.stopBroadcast();
    }
}