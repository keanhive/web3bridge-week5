// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PropToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(uint256 initialSupply) ERC20("PropToken", "PROP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount * 10 ** decimals());
    }
}

contract PropertyManagement is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE  = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE  = keccak256("AGENT_ROLE");
    bytes32 public constant TENANT_ROLE = keccak256("TENANT_ROLE");

    enum PropertyStatus { AVAILABLE, RENTED, SOLD, REMOVED }
    enum PropertyType   { APARTMENT, HOUSE, OFFICE, LAND, WAREHOUSE }

    struct Property {
        uint256        id;
        string         name;
        string         location;
        PropertyType   propertyType;
        uint256        pricePerMonth;
        uint256        salePrice;
        address        owner;
        address        currentTenant;
        PropertyStatus status;
        uint256        listedAt;
        uint256        lastPaymentAt;
        bool           exists;
    }

    PropToken public immutable token;
    uint256 private _propertyIdCounter;

    mapping(uint256 => Property)  private properties;
    mapping(address => uint256[]) private tenantProperties;
    uint256[] private propertyIds;

    event PropertyCreated(uint256 indexed id, string name, string location, PropertyType propertyType, uint256 pricePerMonth, uint256 salePrice, address indexed owner);
    event PropertyRemoved(uint256 indexed id, address indexed removedBy, uint256 timestamp);
    event PropertyRented(uint256 indexed id, address indexed tenant, uint256 amountPaid, uint256 timestamp);
    event PropertySold(uint256 indexed id, address indexed buyer, uint256 amountPaid, uint256 timestamp);
    event RentPaid(uint256 indexed propertyId, address indexed tenant, uint256 amount, uint256 timestamp);
    event TenantEvicted(uint256 indexed propertyId, address indexed tenant, uint256 timestamp);
    event RoleAssigned(bytes32 indexed role, address indexed account, address indexed assignedBy);

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        _;
    }

    modifier onlyAdminOrAgent() {
        require(
            hasRole(ADMIN_ROLE, msg.sender)    ||
            hasRole(AGENT_ROLE, msg.sender)    ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Not an admin or agent"
        );
        _;
    }

    modifier onlyTenant() {
        require(hasRole(TENANT_ROLE, msg.sender), "Not a tenant");
        _;
    }

    modifier propertyExists(uint256 _id) {
        require(properties[_id].exists, "Property does not exist");
        require(properties[_id].status != PropertyStatus.REMOVED, "Property has been removed");
        _;
    }

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = PropToken(_token);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function grantAdminRole(address _account) external onlyAdmin {
        _grantRole(ADMIN_ROLE, _account);
        emit RoleAssigned(ADMIN_ROLE, _account, msg.sender);
    }

    function grantAgentRole(address _account) external onlyAdmin {
        _grantRole(AGENT_ROLE, _account);
        emit RoleAssigned(AGENT_ROLE, _account, msg.sender);
    }

    function grantTenantRole(address _account) external onlyAdminOrAgent {
        _grantRole(TENANT_ROLE, _account);
        emit RoleAssigned(TENANT_ROLE, _account, msg.sender);
    }

    function revokeUserRole(bytes32 _role, address _account) external onlyAdmin {
        _revokeRole(_role, _account);
    }

    function createProperty(
        string   calldata _name,
        string   calldata _location,
        PropertyType      _propertyType,
        uint256           _pricePerMonth,
        uint256           _salePrice
    ) external onlyAdminOrAgent returns (uint256 propertyId) {
        require(bytes(_name).length > 0,     "Name cannot be empty");
        require(bytes(_location).length > 0, "Location cannot be empty");
        require(_pricePerMonth > 0 || _salePrice > 0, "Set at least one price");

        _propertyIdCounter++;
        propertyId = _propertyIdCounter;

        properties[propertyId] = Property({
            id:            propertyId,
            name:          _name,
            location:      _location,
            propertyType:  _propertyType,
            pricePerMonth: _pricePerMonth * 10 ** 18,
            salePrice:     _salePrice     * 10 ** 18,
            owner:         msg.sender,
            currentTenant: address(0),
            status:        PropertyStatus.AVAILABLE,
            listedAt:      block.timestamp,
            lastPaymentAt: 0,
            exists:        true
        });

        propertyIds.push(propertyId);
        emit PropertyCreated(propertyId, _name, _location, _propertyType, _pricePerMonth * 10 ** 18, _salePrice * 10 ** 18, msg.sender);
    }

    function removeProperty(uint256 _id) external propertyExists(_id) {
        Property storage prop = properties[_id];
        require(
            prop.owner == msg.sender              ||
            hasRole(ADMIN_ROLE, msg.sender)        ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender)||
            hasRole(AGENT_ROLE, msg.sender),
            "Not authorised to remove"
        );
        require(prop.status != PropertyStatus.RENTED, "Evict tenant first");

        prop.status = PropertyStatus.REMOVED;
        _removeFromIdList(_id);
        emit PropertyRemoved(_id, msg.sender, block.timestamp);
    }

    function rentProperty(uint256 _id) external nonReentrant onlyTenant propertyExists(_id) {
        Property storage prop = properties[_id];
        require(prop.status == PropertyStatus.AVAILABLE, "Property not available");
        require(prop.pricePerMonth > 0, "Not listed for rent");
        require(prop.currentTenant == address(0), "Already occupied");

        uint256 amount = prop.pricePerMonth;
        require(token.balanceOf(msg.sender) >= amount, "Insufficient PROP balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Approve contract first");

        token.transferFrom(msg.sender, prop.owner, amount);
        prop.currentTenant = msg.sender;
        prop.status        = PropertyStatus.RENTED;
        prop.lastPaymentAt = block.timestamp;
        tenantProperties[msg.sender].push(_id);

        emit PropertyRented(_id, msg.sender, amount, block.timestamp);
        emit RentPaid(_id, msg.sender, amount, block.timestamp);
    }

    function payRent(uint256 _id) external nonReentrant onlyTenant propertyExists(_id) {
        Property storage prop = properties[_id];
        require(prop.status == PropertyStatus.RENTED, "Property not rented");
        require(prop.currentTenant == msg.sender, "You are not the tenant");

        uint256 amount = prop.pricePerMonth;
        require(token.balanceOf(msg.sender) >= amount, "Insufficient PROP balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Approve contract first");

        token.transferFrom(msg.sender, prop.owner, amount);
        prop.lastPaymentAt = block.timestamp;
        emit RentPaid(_id, msg.sender, amount, block.timestamp);
    }

    function buyProperty(uint256 _id) external nonReentrant propertyExists(_id) {
        Property storage prop = properties[_id];
        require(prop.status == PropertyStatus.AVAILABLE, "Not available for sale");
        require(prop.salePrice > 0, "Not listed for sale");

        uint256 amount = prop.salePrice;
        require(token.balanceOf(msg.sender) >= amount, "Insufficient PROP balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Approve contract first");

        address previousOwner = prop.owner;
        token.transferFrom(msg.sender, previousOwner, amount);
        prop.owner         = msg.sender;
        prop.status        = PropertyStatus.SOLD;
        prop.lastPaymentAt = block.timestamp;

        if (!hasRole(AGENT_ROLE, msg.sender)) _grantRole(AGENT_ROLE, msg.sender);

        emit PropertySold(_id, msg.sender, amount, block.timestamp);
    }

    function evictTenant(uint256 _id) external propertyExists(_id) {
        Property storage prop = properties[_id];
        require(
            prop.owner == msg.sender              ||
            hasRole(ADMIN_ROLE, msg.sender)        ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Not authorised to evict"
        );
        require(prop.status == PropertyStatus.RENTED, "Property is not rented");

        address evictedTenant = prop.currentTenant;
        prop.currentTenant    = address(0);
        prop.status           = PropertyStatus.AVAILABLE;
        emit TenantEvicted(_id, evictedTenant, block.timestamp);
    }

    function getProperty(uint256 _id) external view returns (Property memory) {
        require(properties[_id].exists, "Property does not exist");
        return properties[_id];
    }

    function getAllProperties() external view returns (Property[] memory) {
        Property[] memory result = new Property[](propertyIds.length);
        for (uint256 i = 0; i < propertyIds.length; i++) {
            result[i] = properties[propertyIds[i]];
        }
        return result;
    }

    function getAvailableProperties() external view returns (Property[] memory) {
        uint256 count;
        for (uint256 i = 0; i < propertyIds.length; i++) {
            if (properties[propertyIds[i]].status == PropertyStatus.AVAILABLE) count++;
        }
        Property[] memory result = new Property[](count);
        uint256 idx;
        for (uint256 i = 0; i < propertyIds.length; i++) {
            if (properties[propertyIds[i]].status == PropertyStatus.AVAILABLE) {
                result[idx++] = properties[propertyIds[i]];
            }
        }
        return result;
    }

    function getTenantProperties(address _tenant) external view returns (Property[] memory) {
        uint256[] memory ids = tenantProperties[_tenant];
        Property[] memory result = new Property[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = properties[ids[i]];
        }
        return result;
    }

    function totalActiveProperties() external view returns (uint256) {
        return propertyIds.length;
    }

    function getUserRoles(address _account) external view returns (bool isDefaultAdmin, bool isAdmin, bool isAgent, bool isTenant) {
        isDefaultAdmin = hasRole(DEFAULT_ADMIN_ROLE, _account);
        isAdmin        = hasRole(ADMIN_ROLE,          _account);
        isAgent        = hasRole(AGENT_ROLE,          _account);
        isTenant       = hasRole(TENANT_ROLE,         _account);
    }

    function _removeFromIdList(uint256 _id) internal {
        uint256 len = propertyIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (propertyIds[i] == _id) {
                propertyIds[i] = propertyIds[len - 1];
                propertyIds.pop();
                break;
            }
        }
    }
}
