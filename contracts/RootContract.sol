pragma solidity ^0.4.15;

import "./LicenseContract.sol";

contract RootContract {

    /**
     * Assert that the message is sent by the root contract's owner 
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * Assert that the root contract has not been disabled
     */
    modifier notDisabled() {
        require(!disabled);
        _;
    }

    /**
     * The address that owns this root contract and can access the management 
     * interface
     */
    address public owner;

    /**
     * Whether or not this contract is disabled and can thus no longer create 
     * new license contracts.
     *
     * The `Disabled` event is emitted when this variable is set to `true`.
     */
    bool public disabled;

    /**
     * The fee that will be set on each newly created license contract and which
     * will need to be paid for every issuance on the license contract.
     */
    uint128 public defaultFee;

    /** 
     * The addresses of all license contracts created by this root contract.
     */
    address[] public licenseContracts;

    /**
     * Fired every time a new license contract is created.
     *
     * @param licenseContractAddress The address of the newly created license 
     *                               contract
     */
    event LicenseContractCreation(address licenseContractAddress);

    /**
     * Fired when the root contract gets disabled.
     */
    event Disabled();

    // Constructor

    function RootContract() {
        owner = msg.sender;
    }

    // Creating new license contracts

    /**
     * Initiate the creation of a new license contract tailored to the specified
     * issuer. Once this call has be executed, the newly created license 
     * contract needs to be signed before it can issue licenses.
     *
     * This contract is by default the LOB root of the license contract and the 
     * invoker of this function the license contract's issuer.
     *
     * @param issuerName A human readable name of the person or organisation 
     *                   that will use the license contract to issue LOB 
     *                   licenses
     * @param liability The liability that shall be substitute into the 
     *                  liability placeholder of the certificate text
     * @param safekeepingPeriod The amount of years all documents having to do 
     *                          with the audit will be kept by the issuer
     * @param issuerCertificate The SSL certificate that will be used to sign 
     *                          the license contract. See the license contract's
     *                          documentation on the requirements of this 
     *                          certificate
     */
    // TODO: In which format shall the certificate be?
    function createLicenseContract(string issuerName, string liability, uint8 safekeepingPeriod, bytes issuerCertificate) external notDisabled returns (address) {
        var licenseContractAddress = new LicenseContract(msg.sender, issuerName, liability, issuerCertificate, safekeepingPeriod, defaultFee);
        licenseContracts.push(licenseContractAddress);
        LicenseContractCreation(licenseContractAddress);
        return licenseContractAddress;
    }

    // Retrieving license contract addresses

    /**
     * Retrieve the number of license contract addresses stored in the 
     * `liceseContracts` instance variable.
     *
     * @return The number of elements in the `liceseContract` variable
     */
    function licenseContractCount() external constant returns (uint256) {
        return licenseContracts.length;
    }

    // Managing fees

    /**
     * Set the fee of a license contract. See documentation of 
     * `LicenseContract.setFee` for detailed information.
     *
     * This can only be invoked by the root contract's owner.
     *
     * @param licenseContractAddress The address of the license contract for 
     *                               which the fee shall be changed
     * @param newFee The new fee that shall be required for every issuance of 
     *               this license contract
     */
    function setLicenseContractFee(address licenseContractAddress, uint128 newFee) external onlyOwner {
        LicenseContract(licenseContractAddress).setFee(newFee);
    }

    /**
     * Set the fee that is set on every newly created license contract and which 
     * is thus required for every issuance made by that license contract.
     *
     * This can only be invoked by the root contract's owner.
     *
     * @param newDefaultFee The new default fee that shall be set on every newly 
     *                      created license contract
     */
    function setDefaultFee(uint128 newDefaultFee) external onlyOwner {
        defaultFee = newDefaultFee;
    }

    // Managing license contracts

    /**
     * Set the LOB root of a license contract from this contract to a new 
     * address.
     *
     * This can only be invoked by the root contract's owner.
     *
     * @param licenseContractAddress The address of the license contract whose 
     *                               LOB root shall be changed
     * @param newRoot The address that shall from now on be the license 
     *                contract's LOB root
     */
    function setLicenseContractRoot(address licenseContractAddress, address newRoot) external onlyOwner {
        LicenseContract(licenseContractAddress).setLOBRoot(newRoot);
    }

    /**
     * Withdraw fees collected by a license contract from the license contract 
     * and transfer them to the given recpient address.
     *
     * This can only be invoked by the root contract's owner.
     *
     * @param licenseContractAddress The address of the license contract from 
     *                               which collected fees shall be withdrawn
     * @param amount The amount of wei that shall be withdrawn from the license 
     *               contract
     * @param recipient The address to which the withdrawn wei should be sent
     */
    function withdrawFromLicenseContract(address licenseContractAddress, uint256 amount, address recipient) external onlyOwner {
        LicenseContract(licenseContractAddress).withdraw(amount, recipient);
    }

    /**
     * Disable the license contract with the given address, making it unable to 
     * issue any more licenses.
     *
     * This can only be invoked by the root contract's owner.
     *
     * @param licenseContractAddress The address of the license contract that 
     *                               shall be disabled
     */
    function disableLicenseContract(address licenseContractAddress) external onlyOwner {
        LicenseContract(licenseContractAddress).disable();
    }

    // Managing root contract

    /**
     * Set the owner of the root contract to a new address.
     * 
     * This can only be invoked by the current owner.
     *
     * @param newOwner The address of the new owner for this root contract
     */
    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    /**
     * Disable this root contract, making it unable to create any more license 
     * contracts. 
     *
     * This action cannot be undone.
     *
     * Upon successful execution, the `Disabled` event is fired.
     *
     * This can only be invoked by the root contract's owner.
     */
    function disable() external onlyOwner {
        disabled = true;
        Disabled();
    }
}