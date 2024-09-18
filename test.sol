// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdTank {
    address public owner; // Contract owner
    address public admin; // Admin address
    mapping(address => bool) public creators; // Mapping to store creators
    uint public systemCommission; // Total commission collected by the system

    constructor() {
        owner = msg.sender;
        admin = msg.sender;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Modifier to check if the caller is the project creator
    modifier onlyCreator(uint _projectId) {
        require(projects[_projectId].creator == msg.sender, "Only project creator can perform this action");
        _;
    }

    struct Project {
        address creator;
        string name;
        string description;
        uint fundingGoal;
        uint deadline;
        uint amountRaised;
        bool funded;
        address highestFunder;
        mapping(address => uint) contributions;
    }

    mapping(uint => Project) public projects;
    mapping(uint => bool) public isIdUsed;
    uint public totalProjects;
    uint public totalFundedProjects;
    uint public totalFailedProjects;

    event ProjectCreated(uint indexed projectId, address indexed creator, string name, string description, uint fundingGoal, uint deadline);
    event ProjectFunded(uint indexed projectId, address indexed contributor, uint amount);
    event FundsWithdrawn(uint indexed projectId, address indexed withdrawer, uint amount, string withdrawerType);
    event CreatorAdded(address indexed creator);
    event CreatorRemoved(address indexed creator);
    event DeadlineEnhanced(uint indexed projectId, uint additionalSeconds);
    event FundingSuccessful(uint indexed projectId);
    event FundingFailed(uint indexed projectId);

    function createProject(string memory _name, string memory _description, uint _fundingGoal, uint _durationSeconds, uint _id) external {
        require(!isIdUsed[_id], "Project Id is already used");
        isIdUsed[_id] = true;
        require(creators[msg.sender], "Only added creators can create a project");
        projects[_id].creator = msg.sender;
        projects[_id].name = _name;
        projects[_id].description = _description;
        projects[_id].fundingGoal = _fundingGoal;
        projects[_id].deadline = block.timestamp + _durationSeconds;
        projects[_id].amountRaised = 0;
        projects[_id].funded = false;

        emit ProjectCreated(_id, msg.sender, _name, _description, _fundingGoal, block.timestamp + _durationSeconds);
        totalProjects++;
    }

    function fundProject(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        require(!project.funded, "Project is already funded");
        require(msg.value > 0, "Must send some value of ether");

        uint commission = (msg.value * 5) / 100;
        systemCommission += commission;

        uint contributionAmount = msg.value - commission;

        project.amountRaised += contributionAmount;
        project.contributions[msg.sender] += contributionAmount;
        emit ProjectFunded(_projectId, msg.sender, contributionAmount);

        if (project.amountRaised >= project.fundingGoal) {
            project.funded = true;
            totalFundedProjects++;
            emit FundingSuccessful(_projectId);
        }

        if (project.contributions[msg.sender] > project.contributions[project.highestFunder]) {
            project.highestFunder = msg.sender;
        }
    }

    function userWithdrawFunds(uint _projectId) external {
        Project storage project = projects[_projectId];
        require(!project.funded && project.deadline <= block.timestamp, "Funding goal is reached or deadline not passed");
        uint fundContributed = project.contributions[msg.sender];
        payable(msg.sender).transfer(fundContributed);
        emit FundsWithdrawn(_projectId, msg.sender, fundContributed, "user");
    }

    function adminWithdrawFunds(uint _projectId) external onlyAdmin {
        Project storage project = projects[_projectId];
        require(project.funded, "Project is not funded yet");
        payable(admin).transfer(project.amountRaised);
        emit FundsWithdrawn(_projectId, admin, project.amountRaised, "admin");
    }

    function addCreator(address _creator) external onlyAdmin {
        creators[_creator] = true;
        emit CreatorAdded(_creator);
    }

    function removeCreator(address _creator) external onlyAdmin {
        creators[_creator] = false;
        emit CreatorRemoved(_creator);
    }

    function enhanceDeadline(uint _projectId, uint _additionalSeconds) external onlyCreator(_projectId) {
        projects[_projectId].deadline += _additionalSeconds;
        emit DeadlineEnhanced(_projectId, _additionalSeconds);
    }

    function getRemainingTime(uint _projectId) external view returns(uint) {
        if (block.timestamp > projects[_projectId].deadline) {
            return 0;
        } else {
            return projects[_projectId].deadline - block.timestamp;
        }
    }

    function getSuccessfulProjectsCount() external view returns(uint) {
        return totalFundedProjects;
    }

    function getFailedProjectsCount() external view returns(uint) {
        return totalProjects - totalFundedProjects;
    }

    function getTotalSystemCommission() external view returns (uint) {
        return systemCommission;
    }

    function withdrawCommission() external onlyAdmin {
        payable(admin).transfer(systemCommission);
        systemCommission = 0;
    }
}
