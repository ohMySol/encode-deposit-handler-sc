// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./DepositHandler.sol";

contract BootcampManager {
    address public owner;
    
    struct Bootcamp{
        uint256 bootcampId;
        string nameOfBootcamp;
        DepositHandler depositHandler; // Contract managing deposits/withdrawals
        address admin; //admin managing the bootcamp
        int256 depositValue; //may be differenet for each courses? if all coures require 250USDC then we can get delete this
        uint256 startTimestamp; //can also be used as a deadline for when the user has to send their deposit by (user has to send their deposit before the course has started)
        uint256 endTimestamp; //end of course, deposits are now allowed
        //bool isActive; 
    }


    //address[] public admins; //list of all the admins, maybe better to use mapping??

    mapping(address => bool) public admins; // Use mapping to store admins

    Bootcamp[] public bootcamps; //list of all the bootcamps
    

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the Owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only an Admin can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }


    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }


    function removeAdmin(address _admin) external onlyOwner{
        admins[_admin] = false;
    }

    function createBootcamp(string memory _name, address _usdcToken, int256 _depositValue, uint256 _startTimestamp, uint256 _endTimestamp) external onlyAdmin{
        DepositHandler newDepositHandler = new DepositHandler(_usdcToken);
        uint256 _bootcampId = bootcamps.length - 1;

        bootcamps.push(Bootcamp({
            bootcampId: _bootcampId,
            nameOfBootcamp: _name,
            depositHandler: newDepositHandler,
            admin: msg.sender,
            depositValue: _depositValue,
            startTimestamp: _startTimestamp,
            endTimestamp: _endTimestamp


        }));



    }


    function getBootcamp(uint256 _bootcampId) external view returns(
        string memory name,
        address depositHandler,
        address admin,
        int256 depositValue,
        uint256 startTimestamp,
        uint256 endTimestamp
    ){
        require(_bootcampId < bootcamps.length, "Invalid bootcamp ID");
        Bootcamp storage bootcamp = bootcamps[_bootcampId];
        return (bootcamp.nameOfBootcamp, address(bootcamp.depositHandler), bootcamp.admin, bootcamp.depositValue, bootcamp.startTimestamp, bootcamp.endTimestamp);
    }


    





}