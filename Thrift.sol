// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import "witnet-solidity-bridge/contracts/interfaces/IWitnetRandomness.sol";

contract Thrift {
  struct Club {
    string clubName;
  }
  struct Users {
    string userName;
    address userAddress;
  }

  Users[] public user;

  mapping(string => Users[]) public clubToUser;
  mapping(string => uint256) public nameToAmount;
  mapping(string => uint256) public numberOfUsers;
  mapping(address => bool) public hasPaid;
  mapping(string => uint256) public totalAmountInClub;
  mapping(string => uint256) public trackOfUsersThatPaid;
  uint32 public randomness;
  uint time;
  uint256 public latestRandomizingBlock;
  IWitnetRandomness public immutable witnet;

  /// @param _witnetRandomness Address of the WitnetRandomness contract.
  constructor(IWitnetRandomness _witnetRandomness) {
    assert(address(_witnetRandomness) != address(0));
    witnet = _witnetRandomness;
    time = block.timestamp;
  }

  receive() external payable {}

  function requestRandomNumber() external payable {
    latestRandomizingBlock = block.number;
    uint _usedFunds = witnet.randomize{value: msg.value}();
    if (_usedFunds < msg.value) {
      payable(msg.sender).transfer(msg.value - _usedFunds);
    }
  }

  function fetchRandomNumber(string memory _clubName) external {
    assert(latestRandomizingBlock > 0);
    Users[] memory myarr = clubToUser[_clubName];
    uint32 num = uint32(myarr.length);
    // uint256 num = numberOfUsers[_clubName];

    randomness = witnet.random(num, 0, latestRandomizingBlock);
  }

  function createClub(string memory _clubName, string memory _userName) public {
    Users memory clubUser = Users(_userName, msg.sender);
    numberOfUsers[_clubName] = 1;
    clubToUser[_clubName].push(clubUser);
  }

  function addUser(string memory _clubName, string memory _userName, address _user) public {
    require(clubToUser[_clubName].length > 0, "Club Not Found");
    Users memory clubUser = Users(_userName, _user);
    numberOfUsers[_clubName] += 1;
    clubToUser[_clubName].push(clubUser);
  }

  // function getAllUsers(string memory _clubName) public returns (Users[] memory){
  //     Users[] memory all = clubToUser[_clubName];
  //     return all;
  // }
  //sd

  function proposedContirbutionAmount(string memory _clubName, uint256 _proposedAmount) public {
    //   require(clubToUser[_clubName].length>0, "wrong");
    //   amount[_clubName]=_proposedAmount;
    uint256 amountInEther = _proposedAmount * 10 ** 18;
    nameToAmount[_clubName] = amountInEther;
  }

  function intervalInWeeks(string memory _clubName) public view returns (uint256) {
    return numberOfUsers[_clubName];
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getAmountFromClub(string memory _clubName) public view returns (uint256) {
    return nameToAmount[_clubName];
  }

  function sendAmountToContract(string memory _clubName) public payable {
    uint256 amount = getAmountFromClub(_clubName);
    // uint numberOfUsersInTheClub = numberOfUsers[_clubName];
    require(msg.value == amount, "please pay the correct amount");
    require(hasPaid[msg.sender] = false, "User has already paid");
    hasPaid[msg.sender] = true;
    trackOfUsersThatPaid[_clubName] += 1;
    totalAmountInClub[_clubName] += msg.value;
  }

  function hasEveryOnePaid(string memory _clubName) public returns (bool) {
    return trackOfUsersThatPaid[_clubName] == numberOfUsers[_clubName];
  }

  function withdraw(string memory _clubName) public {
    require(block.timestamp > time + 600, "Please wait for 10 minutes until next transaction");
    require(hasPaid[msg.sender] == true, "User has not paid");
    Users storage newArray = clubToUser[_clubName][randomness];

    address payable _receiver = payable(newArray.userAddress);
    _receiver.transfer(totalAmountInClub[_clubName]);
    time = block.timestamp;
  }

  //      uint256 clubId;
  //      mapping (string => Users) public userToClub;
  //     mapping(uint256 => Club) public addClub;
  //     Users[] public user;
  //     mapping(string => Users[]) public clubUsers;

  //     function addUser(string memory _clubName, string memory _userName, address _userAddress) public {

  //        require(clubExists(_clubName)==true,"wrong");
  //         Users memory newUser = Users(_userName, _userAddress);
  //         clubUsers[_clubName].push(newUser);
  //     }

  //     event done(address _creator, string  _clubName);
  //     function createClub(address _creator, string memory _clubName) public{
  //         require(_creator==msg.sender, "Please add your own address");
  //         Club memory cclub = new Club(_clubName,_creator);
  //         // addClub[clubId].creator=_creator;
  //         // addClub[clubId].clubName=_clubName;
  //         clubUsers[_clubName].push(cclub);
  //         clubId++;
  //         emit done( _creator,  _clubName);
  //     }
  //     // function addUser(string memory _clubName,address _userAddress, string memory _userName) public {
  //     // //  Club club = new Club(_clubName,_clubAddress);
  //     // if()
  //     //  userToClub[_clubName].userName = _userName;
  //     //  userToClub[_clubName].userAddress = _userAddress;

  //     // }
  //     function clubExists(string memory _clubName) public view returns (bool) {
  //     return clubUsers[_clubName].length > 0;
  // }
  //     // function addUser(address _user, string memory _name) public{

  //     // }
  //     function getAllClubs() public view returns(Club[] memory){
  //         Club[] memory result = new Club[](clubId);
  //         uint256 i = 0;
  //         for (uint256 key = 0; key <clubId; key++) {
  //             if (bytes(addClub[key].clubName).length != 0) {
  //                 result[i] = addClub[key];
  //                 i++;
  //             }
  //         }
  //         return result;
  //     }
  //     function getClubWithId(uint256 _id) public view returns(string memory, address){
  //         return(addClub[_id].clubName, addClub[_id].creator);
  //     }
}
