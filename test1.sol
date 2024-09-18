// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    // struct to store project details
    struct Project {
        string name;
        uint deadline;
        uint amountRaised;
        bool funded;
    }
    // projectId => project details
    mapping(uint => Project) public projects;

    // Total number of projects created
    uint public totalProjects;

    // Total number of funded projects
    uint public totalFundedProjects;

    // Total number of failed projects
    uint public totalFailedProjects;

    // Total commission collected by the system
    uint public systemCommission;

    constructor() {
        totalProjects = 0;
        totalFundedProjects = 0;
        totalFailedProjects = 0;
        systemCommission = 0;
    }

    // Function to create a new project
    function createProject(uint _deadline, uint _id, string memory _name) external {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        projects[_id] = Project({
            name: _name,
            deadline: _deadline,
            amountRaised: 0,
            funded: false
        });
        totalProjects++;
    }

    // Function to fund a project
    function fundProject(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        require(block.timestamp <= project.deadline, "Project deadline is already passed");
        require(!project.funded, "Project is already funded");
        require(msg.value > 0, "Must send some value of ether");

        // Calculate commission
        uint commission = msg.value * 5 / 100;
        systemCommission += commission;

        // Deduct commission from the contributed amount
        uint contributionAmount = msg.value - commission;

        project.amountRaised += contributionAmount;
        if (project.amountRaised >= 100) {
            project.funded = true;
            totalFundedProjects++;
        } else if (block.timestamp >= project.deadline) {
            totalFailedProjects++;
        }
    }

    // Function to enhance the deadline of a project
    function enhanceDeadline(uint _projectId, uint _additionalSeconds) external {
        Project storage project = projects[_projectId];
        require(block.timestamp <= project.deadline, "Project deadline is already passed");
        project.deadline += _additionalSeconds;
    }

    // Function to withdraw system commission
    function withdrawCommission() external {
        // Only the system admin can withdraw commission
        // Implement this functionality based on your access control mechanism
    }

    // Function to get remaining time for project funding deadline
    function getRemainingTime(uint _projectId) external view returns(uint) {
        if (block.timestamp > projects[_projectId].deadline) {
            return 0;
        } else {
            return projects[_projectId].deadline - block.timestamp;
        }
    }

    // Function to return the number of projects which raised successful funding
    function getSuccessfulProjects() external view returns(uint) {
        return totalFundedProjects;
    }

    // Function to return the number of projects which failed to raise enough funds
    function getFailedProjects() external view returns(uint) {
        return totalFailedProjects;
    }
}
