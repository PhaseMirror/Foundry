// contracts/SUGDAO.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SUGDAO
 * @dev Sovereign Urban Garden DAO with Lifebushido triadic governance
 *      and Multiplicity Stablecoin integration.
 */
contract SUGDAO is AccessControl, ReentrancyGuard {
    // ==================== Constants ====================
    
    bytes32 public constant TRIAD_ROLE = keccak256("TRIAD_ROLE");
    bytes32 public constant CIRCLE_ROLE = keccak256("CIRCLE_ROLE");
    bytes32 public constant FAMILY_ROLE = keccak256("FAMILY_ROLE");
    bytes32 public constant PHASE_MIRROR_ROLE = keccak256("PHASE_MIRROR_ROLE");
    
    uint256 public constant MAX_TRIADS = 3;
    uint256 public constant MAX_CIRCLES = 9;
    uint256 public constant MAX_FAMILIES = 27;
    
    // ==================== State Variables ====================
    
    IERC20 public mscToken;
    
    // Triadic scaling state
    mapping(uint256 => Triad) public triads;
    mapping(uint256 => Circle) public circles;
    mapping(uint256 => Family) public families;
    
    uint256 public triadCount;
    uint256 public circleCount;
    uint256 public familyCount;
    
    // Governance state
    uint256 public resonanceThreshold = 70;  // R(t) * 100
    uint256 public sovereigntyThreshold = 60; // S(t) * 100
    
    // Telemetry state
    bytes32 public lastTelemetryHash;
    uint256 public lastUpdate;
    
    // ==================== Structs ====================
    
    struct Triad {
        address[3] members;
        uint256 reciprocityScore;  // R_i(t) * 100
        uint256 resonanceScore;    // R(t) * 100
        uint256 sovereigntyScore;  // S(t) * 100
        uint256 lastCheckIn;
        bool active;
    }
    
    struct Circle {
        uint256[3] triadIds;
        uint256 coordinationScore;
        uint256 lastMeeting;
        bool active;
    }
    
    struct Family {
        uint256[3] circleIds;
        uint256 strategicAlignment;
        uint256 lastCouncil;
        bool active;
    }
    
    struct TelemetryData {
        bytes32 dataHash;
        uint256 timestamp;
        uint256 resonance;
        uint256 sovereignty;
        uint256 embodiedHealth;
        uint256 mscValue;
    }
    
    // ==================== Events ====================
    
    event TriadCreated(uint256 indexed triadId, address[3] members);
    event CircleCreated(uint256 indexed circleId, uint256[3] triadIds);
    event FamilyCreated(uint256 indexed familyId, uint256[3] circleIds);
    event ResonanceUpdate(uint256 resonance, uint256 timestamp);
    event PhaseMirrorActivated(uint256 triadId, string resolution);
    event EmbodiedCheckIn(uint256 triadId, address member, string state);
    event MSCValuationUpdated(uint256 value);
    
    // ==================== Modifiers ====================
    
    modifier onlyTriad(uint256 triadId) {
        require(triads[triadId].active, "Triad not active");
        _;
    }
    
    modifier onlyActiveTriadMember(uint256 triadId, address member) {
        bool isMember = false;
        for (uint i = 0; i < triads[triadId].members.length; i++) {
            if (triads[triadId].members[i] == member) {
                isMember = true;
                break;
            }
        }
        require(isMember, "Not a triad member");
        _;
    }
    
    // ==================== Constructor ====================
    
    constructor(address _mscToken) {
        mscToken = IERC20(_mscToken);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PHASE_MIRROR_ROLE, msg.sender);
    }
    
    // ==================== Triad Functions ====================
    
    function createTriad(address[3] calldata members) external nonReentrant {
        require(triadCount < MAX_TRIADS, "Max triads reached");
        require(members.length == 3, "Must have 3 members");
        
        for (uint i = 0; i < 3; i++) {
            require(members[i] != address(0), "Invalid member");
            for (uint j = i + 1; j < 3; j++) {
                require(members[i] != members[j], "Duplicate member");
            }
        }
        
        uint256 triadId = triadCount++;
        
        Triad storage triad = triads[triadId];
        triad.members = members;
        triad.active = true;
        triad.lastCheckIn = block.timestamp;
        
        for (uint i = 0; i < 3; i++) {
            _grantRole(TRIAD_ROLE, members[i]);
        }
        
        emit TriadCreated(triadId, members);
    }
    
    function embodiedCheckIn(
        uint256 triadId, 
        string calldata state
    ) external onlyActiveTriadMember(triadId, msg.sender) {
        triads[triadId].lastCheckIn = block.timestamp;
        uint256 healthScore = _computeEmbodiedHealth(state);
        emit EmbodiedCheckIn(triadId, msg.sender, state);
    }
    
    function updateReciprocity(
        uint256 triadId, 
        uint256 score
    ) external onlyRole(PHASE_MIRROR_ROLE) {
        require(score <= 100, "Score must be <= 100");
        triads[triadId].reciprocityScore = score;
    }
    
    // ==================== Circle Functions ====================
    
    function createCircle(uint256[3] calldata triadIds) external onlyRole(PHASE_MIRROR_ROLE) {
        require(circleCount < MAX_CIRCLES, "Max circles reached");
        for (uint i = 0; i < 3; i++) {
            require(triads[triadIds[i]].active, "Triad not active");
        }
        
        uint256 circleId = circleCount++;
        Circle storage circle = circles[circleId];
        circle.triadIds = triadIds;
        circle.active = true;
        circle.lastMeeting = block.timestamp;
        
        emit CircleCreated(circleId, triadIds);
    }
    
    // ==================== Family Functions ====================
    
    function createFamily(uint256[3] calldata circleIds) external onlyRole(PHASE_MIRROR_ROLE) {
        require(familyCount < MAX_FAMILIES, "Max families reached");
        for (uint i = 0; i < 3; i++) {
            require(circles[circleIds[i]].active, "Circle not active");
        }
        
        uint256 familyId = familyCount++;
        Family storage family = families[familyId];
        family.circleIds = circleIds;
        family.active = true;
        family.lastCouncil = block.timestamp;
        
        emit FamilyCreated(familyId, circleIds);
    }
    
    // ==================== Telemetry Functions ====================
    
    function submitTelemetry(
        bytes32 dataHash,
        uint256 resonance,
        uint256 sovereignty,
        uint256 embodiedHealth,
        uint256 mscValue
    ) external nonReentrant {
        require(resonance <= 100, "Resonance must be <= 100");
        require(sovereignty <= 100, "Sovereignty must be <= 100");
        
        lastTelemetryHash = dataHash;
        lastUpdate = block.timestamp;
        
        if (resonance > resonanceThreshold) {
            resonanceThreshold = resonance;
        }
        
        emit ResonanceUpdate(resonance, block.timestamp);
        emit MSCValuationUpdated(mscValue);
    }
    
    // ==================== Phase Mirror Functions ====================
    
    function activatePhaseMirror(
        uint256 triadId,
        string calldata resolution
    ) external onlyRole(PHASE_MIRROR_ROLE) onlyActiveTriadMember(triadId, msg.sender) {
        require(triads[triadId].active, "Triad not active");
        emit PhaseMirrorActivated(triadId, resolution);
    }
    
    // ==================== View Functions ====================
    
    function getTriad(uint256 triadId) external view returns (Triad memory) {
        return triads[triadId];
    }
    
    function getCircle(uint256 circleId) external view returns (Circle memory) {
        return circles[circleId];
    }
    
    function getFamily(uint256 familyId) external view returns (Family memory) {
        return families[familyId];
    }
    
    function getAggregateResonance() external view returns (uint256) {
        uint256 totalResonance = 0;
        uint256 activeCount = 0;
        for (uint i = 0; i < triadCount; i++) {
            if (triads[i].active) {
                totalResonance += triads[i].resonanceScore;
                activeCount++;
            }
        }
        if (activeCount == 0) return 0;
        return totalResonance / activeCount;
    }
    
    // ==================== Internal Functions ====================
    
    function _computeEmbodiedHealth(string memory state) internal pure returns (uint256) {
        if (keccak256(bytes(state)) == keccak256("ventral")) return 90;
        if (keccak256(bytes(state)) == keccak256("sympathetic")) return 50;
        if (keccak256(bytes(state)) == keccak256("dorsal")) return 10;
        return 50;
    }
}
