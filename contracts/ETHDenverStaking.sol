pragma solidity ^0.4.24;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/zeppelin-solidity/contracts/access/SignatureBouncer.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ECRecovery.sol";


contract ETHDenverStaking is SignatureBouncer, Pausable {
  
    using SafeMath for uint256;
    using ECRecovery for bytes32;

    event UserStake(address userAddress, address stakedBy, uint amountStaked);
    event UserRecoupStake(address userAddress, address stakedBy, uint amountStaked);

    // Debug events
    event debugBytes32(bytes32 _msg);
    event debugBytes(bytes _msg);
    event debugString(string _msg);
    event debugAddress(address _address);

    // signer authorized to allow staking
    address public authorizedStakeGrantAddress = 0xc1E19BDD3DBBA6c070579083E3B0D4C92fcaE0B3;
    
    // signer authorized to allow the recouping staked amount
    address public authorizedRecoupStakeGrantAddress = 0xc1E19BDD3DBBA6c070579083E3B0D4C92fcaE0B3;

    // Mapping associating the userAddress (uPort address) with the wallet (metamask address) that has staked for him
    mapping (address => address) public userStakedAddress; 

    // Mapping containing the amount staked for a given userAddress (uPort address)
    mapping (address => uint256) public stakedAmount;

    function setAuthorizedStakeGrantAddress(address _signer) public onlyOwner {
        authorizedStakeGrantAddress = _signer;
    }

    function setAuthorizedRecoupStakeGrantAddress(address _signer) public onlyOwner {
        authorizedRecoupStakeGrantAddress = _signer;
    }

    // function withdrawFunds(address )

    // function allow the staking for a participant
    function stake(address _userAddress, uint _expiringDate, bytes _signature) public payable {
        bytes32 hashMessage = keccak256(abi.encodePacked(_userAddress, msg.value, _expiringDate));
        address signer = hashMessage.toEthSignedMessageHash().recover(_signature);
        // emit debugAddress(signer);
        // emit debugAddress(authorizedStakeGrantAddress);
        
        require(signer == authorizedStakeGrantAddress, "Signature is not valid");

        require(_expiringDate > block.timestamp, "Grant is expired");

        // require(userStakedAddress[_userAddress] == 0, "User has already stake!");

        stakedAmount[_userAddress] = msg.value;
        userStakedAddress[_userAddress] = msg.sender;

        emit UserStake(_userAddress, msg.sender, msg.value);
    }

    function stake2(address _userAddress, uint _expiringDate, bytes _signature) public payable  onlyValidSignatureAndData(_signature) {
        require(_expiringDate > block.timestamp, "Grant is expired");
        
        require(userStakedAddress[_userAddress] == 0, "User has already stake!");

        stakedAmount[_userAddress] = msg.value;
        userStakedAddress[_userAddress] = msg.sender;

        emit UserStake(_userAddress, msg.sender, msg.value);
    }
    

    // function allow the staking for a participant
    function recoupStake(address _userAddress, uint _expiringDate, bytes _signature) public {
        bytes32 hashMessage = keccak256(abi.encodePacked(_userAddress, _expiringDate));
        address signer = hashMessage.toEthSignedMessageHash().recover(_signature);
        
        require(signer == authorizedRecoupStakeGrantAddress, "Signature is not valid");
        require(_expiringDate > block.timestamp, "Grant is expired");
        require(userStakedAddress[_userAddress] != 0, "User has not stake!");

        address stakedBy = userStakedAddress[_userAddress];
        uint256 amount = stakedAmount[_userAddress];

        require(address(this).balance >= amount, "Not enough funds on the contract");
        require(amount > 0, "User has already recoup the staking");

        stakedBy.transfer(amount);
        stakedAmount[_userAddress] = 0;

        emit UserRecoupStake(_userAddress, stakedBy, amount);
    }

    
    
}