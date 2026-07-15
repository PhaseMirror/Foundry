package main

import (
	"fmt"
	"time"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type WormContract struct {
	contractapi.Contract
}

func (s *WormContract) AppendDigest(ctx contractapi.TransactionContextInterface, key string, payload string, severity string) error {
	// 1. Versioned Key: append timestamp to ensure immutability and uniqueness
	timestamp := time.Now().UTC().Format(time.RFC3339)
	versionedKey := fmt.Sprintf("%s-%s", key, timestamp)
	
	// 2. Append immutable record
	err := ctx.GetStub().PutState(versionedKey, []byte(payload))
	if err != nil {
		return fmt.Errorf("failed to put state: %v", err)
	}

	// 3. Dynamic SBEP for critical keys
	if severity == "CRITICAL" {
		// Enforce strict policy: Governance AND Referee
		policy := `AND('GovernanceMSP.member','RefereeMSP.member')`
		err = ctx.GetStub().SetStateValidationParameter(versionedKey, []byte(policy))
		if err != nil {
			return fmt.Errorf("failed to set critical SBEP for key %s: %v", versionedKey, err)
		}
		// 4. Audit policy application
		s.LogPolicyChange(ctx, versionedKey, "DEFAULT", policy)
	}
	
	return nil
}

// LogPolicyChange creates an immutable audit trail for SBEP modifications
func (s *WormContract) LogPolicyChange(ctx contractapi.TransactionContextInterface, key string, oldPolicy string, newPolicy string) error {
	auditKey := fmt.Sprintf("AUDIT-%s-%d", key, time.Now().Unix())
	auditEntry := fmt.Sprintf("Policy change on %s: %s -> %s", key, oldPolicy, newPolicy)
	return ctx.GetStub().PutState(auditKey, []byte(auditEntry))
}

func main() {
	// Chaincode instantiation logic...
}
