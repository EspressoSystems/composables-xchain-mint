// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

/// @title Interface for CREATE3 Factory
/// @notice Defines methods for deploying contracts deterministically using CREATE3.
interface ICREATE3Factory {
    /// @notice Deploys a contract with `msg.value` Ether to a deterministic address
    /// @param salt The CREATE3 salt
    /// @param creationCode The creation code of the contract to deploy
    /// @return deployed The address of the deployed contract
    function deploy(bytes32 salt, bytes memory creationCode) external payable returns (address deployed);

    /// @notice Predicts the address of a deployed contract
    /// @param deployer The address of the deployer
    /// @param salt The CREATE3 salt
    /// @return deployed The predicted address of the deployed contract
    function getDeployed(address deployer, bytes32 salt) external view returns (address deployed);
}
