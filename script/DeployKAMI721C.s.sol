// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {KAMI721C} from "../contracts/KAMI721C.sol";
import {CreatorTokenTransferValidator} from "../contracts/CreatorTokenTransferValidator.sol";
import {MockERC20} from "../contracts/MockERC20.sol";

/**
 * @title DeployKAMI721C
 * @dev Script to deploy KAMI721C contract with proper configuration
 */
contract DeployKAMI721C is Script {
    // Default USDC addresses with correct checksums
    address constant MAINNET_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant GOERLI_USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant POLYGON_USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant MUMBAI_USDC = 0xe11A86849d99F524cAC3E7A0Ec1241828e332C62;

    function run() public {
        // Get configuration from environment variables or use defaults
        string memory nftName = vm.envString("NFT_NAME");
        if (bytes(nftName).length == 0) {
            nftName = "KAMI NFT Collection";
        }
        
        string memory nftSymbol = vm.envString("NFT_SYMBOL");
        if (bytes(nftSymbol).length == 0) {
            nftSymbol = "KAMI";
        }
        
        string memory baseURI = vm.envString("BASE_URI");
        if (bytes(baseURI).length == 0) {
            baseURI = "https://metadata-api.example.com/token/";
        }
        
        uint8 securityLevel = 1;
        if (vm.envUint("SECURITY_LEVEL") != 0) {
            securityLevel = uint8(vm.envUint("SECURITY_LEVEL"));
        }
        
        // Get network-specific USDC address or deploy a mock
        address usdcAddress;
        uint256 chainId = block.chainid;
        
        if (chainId == 1) { // Mainnet
            usdcAddress = vm.envAddress("MAINNET_USDC_ADDRESS");
            if (usdcAddress == address(0)) {
                usdcAddress = MAINNET_USDC;
            }
        } else if (chainId == 5) { // Goerli
            usdcAddress = vm.envAddress("GOERLI_USDC_ADDRESS");
            if (usdcAddress == address(0)) {
                usdcAddress = GOERLI_USDC;
            }
        } else if (chainId == 11155111) { // Sepolia
            usdcAddress = vm.envAddress("SEPOLIA_USDC_ADDRESS");
            if (usdcAddress == address(0)) {
                usdcAddress = SEPOLIA_USDC;
            }
        } else if (chainId == 137) { // Polygon
            usdcAddress = vm.envAddress("POLYGON_USDC_ADDRESS");
            if (usdcAddress == address(0)) {
                usdcAddress = POLYGON_USDC;
            }
        } else if (chainId == 80001) { // Mumbai
            usdcAddress = vm.envAddress("MUMBAI_USDC_ADDRESS");
            if (usdcAddress == address(0)) {
                usdcAddress = MUMBAI_USDC;
            }
        }
        
        vm.startBroadcast();
        
        // If on a local network, deploy a mock USDC
        if (chainId == 31337 || chainId == 1337) {
            console.log("Deploying MockERC20 as USDC on local network...");
            MockERC20 mockUsdc = new MockERC20("USD Coin", "USDC", 6);
            usdcAddress = address(mockUsdc);
            console.log("MockERC20 (USDC) deployed to: %s", usdcAddress);
        }
        
        // Deploy the transfer validator
        console.log("Deploying CreatorTokenTransferValidator...");
        CreatorTokenTransferValidator validator = new CreatorTokenTransferValidator();
        address validatorAddress = address(validator);
        console.log("CreatorTokenTransferValidator deployed to: %s", validatorAddress);
        
        // Deploy the KAMI721C contract
        console.log("Deploying KAMI721C with USDC address: %s", usdcAddress);
        KAMI721C kami721c = new KAMI721C(
            usdcAddress,
            nftName,
            nftSymbol,
            baseURI
        );
        address kami721cAddress = address(kami721c);
        console.log("KAMI721C deployed to: %s", kami721cAddress);
        
        // Set transfer validator for KAMI721C
        console.log("Setting transfer validator for KAMI721C...");
        kami721c.setTransferValidator(validatorAddress);
        
        // Configure security policy
        console.log("Setting security policy for KAMI721C (level %d)...", securityLevel);
        validator.setCollectionSecurityPolicy(
            kami721cAddress, 
            securityLevel,
            0, // Default operator whitelist ID
            0  // Default contract receivers allowlist ID
        );
        
        // Add msg.sender to operator whitelist for easier testing
        console.log("Adding deployer to operator whitelist...");
        validator.addToList(0, msg.sender);
        
        console.log("Deployment completed successfully!");
        console.log("-----------------------------------");
        console.log("Summary:");
        console.log("KAMI721C: %s", kami721cAddress);
        console.log("TransferValidator: %s", validatorAddress);
        console.log("USDC: %s", usdcAddress);
        console.log("-----------------------------------");
        
        vm.stopBroadcast();
    }
} 