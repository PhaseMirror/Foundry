// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "./utils/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";
 

/// @title BreakGlassEscrow
/// @notice Verifies break‑glass proofs, escrows stake, and allows DAO to slash or refund. No PHI is stored.
contract BreakGlassEscrow is Ownable, ReentrancyGuard {
    IGroth16Verifier public verifier; // breakglass.circom

    address public dao;        // resolver authority
    address public treasury;   // where slashed funds go

    uint256 public minStake = 0.1 ether; // policy‑defined
    uint16 public slashBps = 5000;       // 50% by default

    struct CaseInfo {
        address provider;      // msg.sender that opened
        uint64 timebound;      // epoch seconds after which provider may self‑refund if unresolved
        bytes32 caseCommitment;// public case commitment
        uint256 stake;         // escrowed amount
        bool resolved;         // finalized by DAO or by timeout refund
        bool slashed;          // resolution outcome
    }

    // key: bg_nullifier
    mapping(bytes32 => CaseInfo) public cases;

    event VerifierSet(address v);
    event ParamsSet(uint256 minStake, uint16 slashBps, address dao, address treasury);
    event Opened(bytes32 indexed nullifier, address indexed provider, uint16 reasonCode, uint64 timebound, bytes32 caseCommitment, uint256 stake);
    event Resolved(bytes32 indexed nullifier, bool slashed, uint256 paidToTreasury, uint256 refunded);

    error InvalidProof();
    error AlreadyOpened();
    error NotProvider();
    error NotDAO();
    error TooSmallStake();
    error NotActive();
    error NotExpired();

    constructor(address owner_, address dao_, address treasury_, address verifier_) Ownable(owner_) {
        dao = dao_;
        treasury = treasury_;
        verifier = IGroth16Verifier(verifier_);
        emit ParamsSet(minStake, slashBps, dao, treasury);
        emit VerifierSet(verifier_);
    }

    function setParams(uint256 minStake_, uint16 slashBps_, address dao_, address treasury_) external onlyOwner {
        minStake = minStake_;
        slashBps = slashBps_;
        dao = dao_;
        treasury = treasury_;
        emit ParamsSet(minStake, slashBps, dao, treasury);
    }

    function setVerifier(address v) external onlyOwner { verifier = IGroth16Verifier(v); emit VerifierSet(v); }

    /// Public signals order must match circuit:
    /// [0]=reason_code [1]=provider_pk [2]=timebound [3]=case_commitment [4]=bg_nullifier
    function openBreakGlass(
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[5] calldata pub
    ) external payable nonReentrant {
        // fixed-size pub input (5) expected by verifier
        if (msg.value < minStake) revert TooSmallStake();
        if (!verifier.verifyProof(pA, pB, pC, pub)) revert InvalidProof();

        address provider = address(uint160(pub[1]));
        if (provider != msg.sender) revert NotProvider();

        uint64 timebound = uint64(pub[2]);
        require(block.timestamp <= timebound, "expired");

        bytes32 key = bytes32(pub[4]);
        if (cases[key].provider != address(0)) revert AlreadyOpened();

        cases[key] = CaseInfo({
            provider: provider,
            timebound: timebound,
            caseCommitment: bytes32(pub[3]),
            stake: msg.value,
            resolved: false,
            slashed: false
        });

        emit Opened(key, provider, uint16(pub[0]), timebound, bytes32(pub[3]), msg.value);
    }

    /// DAO resolution: slash or refund.
    function resolve(bytes32 nullifier, bool slash_) external nonReentrant {
        if (msg.sender != dao) revert NotDAO();
        CaseInfo storage c = cases[nullifier];
        if (c.provider == address(0) || c.resolved) revert NotActive();
        c.resolved = true;
        c.slashed = slash_;

        uint256 paidTreasury = 0;
        uint256 refund = 0;
        if (slash_) {
            uint256 cut = (c.stake * slashBps) / 10000;
            paidTreasury = cut;
            refund = c.stake - cut;
            if (paidTreasury > 0 && treasury != address(0)) {
                (bool okT, ) = treasury.call{value: paidTreasury}("");
                require(okT, "treasury-xfer-fail");
            }
        } else {
            refund = c.stake;
        }
        if (refund > 0) {
            (bool okP, ) = c.provider.call{value: refund}("");
            require(okP, "refund-fail");
        }

        emit Resolved(nullifier, slash_, paidTreasury, refund);
    }

    /// Provider can self‑refund after timebound if unresolved.
    function timeoutRefund(bytes32 nullifier) external nonReentrant {
        CaseInfo storage c = cases[nullifier];
        if (c.provider == address(0) || c.resolved) revert NotActive();
        if (msg.sender != c.provider) revert NotProvider();
        if (block.timestamp <= c.timebound) revert NotExpired();
        c.resolved = true;
        (bool ok, ) = c.provider.call{value: c.stake}("");
        require(ok, "refund-fail");
        emit Resolved(nullifier, false, 0, c.stake);
    }
}
