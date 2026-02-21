// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SchoolManagement is Ownable {
    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    enum Level {
        LEVEL_100,
        LEVEL_200,
        LEVEL_300,
        LEVEL_400
    }

    enum PaymentStatus {
        NOT_PAID,
        PAID
    }

    enum StudentStatus {
        ACTIVE,
        REMOVED,
        GRADUATED
    }

    enum StaffStatus {
        ACTIVE,
        SUSPENDED,
        TERMINATED
    }

    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Student {
        uint256 id;
        string name;
        address wallet;
        Level level;
        StudentStatus status;
        PaymentStatus paymentStatus;
        uint256 feePaid;
        uint256 paymentTimestamp;
    }

    struct Staff {
        uint256 id;
        string name;
        address wallet;
        string role;
        uint256 salary;
        uint256 lastPaidAt;
        StaffStatus status;
    }

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable paymentToken;

    uint256 private studentCounter;
    uint256 private staffCounter;

    mapping(address => Student) public students;
    mapping(address => Staff) public staffs;

    address[] private studentList;
    address[] private staffList;

    mapping(Level => uint256) public levelFees;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event StudentRegistered(address indexed student, Level level, uint256 fee);
    event StudentRemoved(address indexed student);
    event StudentGraduated(address indexed student);
    event StudentFeePaid(address indexed student, uint256 amount);

    event StaffEmployed(address indexed staff, uint256 salary);
    event StaffSuspended(address indexed staff);
    event StaffReEmployed(address indexed staff);
    event StaffTerminated(address indexed staff);
    event StaffPaid(address indexed staff, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _paymentToken,
        uint256 fee100,
        uint256 fee200,
        uint256 fee300,
        uint256 fee400
    ) Ownable(msg.sender) {
        require(_paymentToken != address(0), "Invalid token");

        paymentToken = IERC20(_paymentToken);

        levelFees[Level.LEVEL_100] = fee100;
        levelFees[Level.LEVEL_200] = fee200;
        levelFees[Level.LEVEL_300] = fee300;
        levelFees[Level.LEVEL_400] = fee400;
    }

    /*//////////////////////////////////////////////////////////////
                          STUDENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function registerStudent(
        string calldata name,
        Level level
    ) external {
        require(students[msg.sender].wallet == address(0), "Already registered");

        uint256 fee = levelFees[level];
        require(fee > 0, "Invalid fee");

        paymentToken.transferFrom(msg.sender, address(this), fee);

        studentCounter++;

        students[msg.sender] = Student({
            id: studentCounter,
            name: name,
            wallet: msg.sender,
            level: level,
            status: StudentStatus.ACTIVE,
            paymentStatus: PaymentStatus.PAID,
            feePaid: fee,
            paymentTimestamp: block.timestamp
        });

        studentList.push(msg.sender);

        emit StudentRegistered(msg.sender, level, fee);
        emit StudentFeePaid(msg.sender, fee);
    }

    function removeStudent(address student) external onlyOwner {
        require(students[student].status == StudentStatus.ACTIVE, "Not active");
        students[student].status = StudentStatus.REMOVED;

        emit StudentRemoved(student);
    }

    function graduateStudent(address student) external onlyOwner {
        require(students[student].status == StudentStatus.ACTIVE, "Not active");
        students[student].status = StudentStatus.GRADUATED;

        emit StudentGraduated(student);
    }

    function getAllStudents() external view returns (address[] memory) {
        return studentList;
    }

    /*//////////////////////////////////////////////////////////////
                          STAFF FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function employStaff(
        string calldata name,
        address wallet,
        string calldata role,
        uint256 salary
    ) external onlyOwner {
        require(wallet != address(0), "Invalid address");
        require(staffs[wallet].wallet == address(0), "Already exists");

        staffCounter++;

        staffs[wallet] = Staff({
            id: staffCounter,
            name: name,
            wallet: wallet,
            role: role,
            salary: salary,
            lastPaidAt: 0,
            status: StaffStatus.ACTIVE
        });

        staffList.push(wallet);

        emit StaffEmployed(wallet, salary);
    }

    function suspendStaff(address staff) external onlyOwner {
        require(staffs[staff].status == StaffStatus.ACTIVE, "Not active");
        staffs[staff].status = StaffStatus.SUSPENDED;

        emit StaffSuspended(staff);
    }

    function reEmployStaff(address staff) external onlyOwner {
        require(
            staffs[staff].status == StaffStatus.SUSPENDED ||
            staffs[staff].status == StaffStatus.TERMINATED,
            "Invalid status"
        );

        staffs[staff].status = StaffStatus.ACTIVE;

        emit StaffReEmployed(staff);
    }

    function terminateStaff(address staff) external onlyOwner {
        require(staffs[staff].wallet != address(0), "Not found");
        staffs[staff].status = StaffStatus.TERMINATED;

        emit StaffTerminated(staff);
    }

    function payStaff(address staff) external onlyOwner {
        Staff storage s = staffs[staff];
        require(s.status == StaffStatus.ACTIVE, "Staff not active");
        require(s.salary > 0, "No salary");

        paymentToken.transfer(staff, s.salary);
        s.lastPaidAt = block.timestamp;

        emit StaffPaid(staff, s.salary);
    }

    function getAllStaffs() external view returns (address[] memory) {
        return staffList;
    }

    /*//////////////////////////////////////////////////////////////
                        TREASURY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function withdraw(address to, uint256 amount) external onlyOwner {
        paymentToken.transfer(to, amount);
    }
}
