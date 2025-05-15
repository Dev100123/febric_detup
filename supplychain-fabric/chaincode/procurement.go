package main

import (
    "encoding/json"
    "fmt"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing purchase orders
type SmartContract struct {
    contractapi.Contract
}

// PurchaseOrder describes the properties of a purchase order
type PurchaseOrder struct {
    ID        string `json:"id"`
    Buyer     string `json:"buyer"`
    Supplier  string `json:"supplier"`
    Item      string `json:"item"`
    Quantity  int    `json:"quantity"`
    Status    string `json:"status"`
    CreatedAt string `json:"createdAt"`
    UpdatedAt string `json:"updatedAt"`
}

// CreatePO creates a new purchase order on the ledger
func (s *SmartContract) CreatePO(ctx contractapi.TransactionContextInterface, id string, buyer string, supplier string, item string, quantity int, createdAt string) error {
    existingPO, err := ctx.GetStub().GetState(id)
    if err != nil {
        return fmt.Errorf("failed to read purchase order: %v", err)
    }
    if existingPO != nil {
        return fmt.Errorf("purchase order with ID %s already exists", id)
    }

    po := PurchaseOrder{
        ID:        id,
        Buyer:     buyer,
        Supplier:  supplier,
        Item:      item,
        Quantity:  quantity,
        Status:    "created",
        CreatedAt: createdAt,
        UpdatedAt: createdAt,
    }

    poJSON, err := json.Marshal(po)
    if err != nil {
        return fmt.Errorf("failed to marshal purchase order: %v", err)
    }

    return ctx.GetStub().PutState(id, poJSON)
}

// GetPO retrieves a purchase order from the ledger by ID
func (s *SmartContract) GetPO(ctx contractapi.TransactionContextInterface, id string) ([]byte, error) {
    poJSON, err := ctx.GetStub().GetState(id)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if poJSON == nil {
        return nil, fmt.Errorf("purchase order with ID %s does not exist", id)
    }

    return poJSON, nil
}

// UpdatePOStatus updates the status of an existing purchase order
func (s *SmartContract) UpdatePOStatus(ctx contractapi.TransactionContextInterface, id string, newStatus string, updatedAt string) error {
    poJSON, err := ctx.GetStub().GetState(id)
    if err != nil {
        return fmt.Errorf("failed to read purchase order: %v", err)
    }
    if poJSON == nil {
        return fmt.Errorf("purchase order with ID %s does not exist", id)
    }

    var po PurchaseOrder
    err = json.Unmarshal(poJSON, &po)
    if err != nil {
        return fmt.Errorf("failed to unmarshal purchase order: %v", err)
    }

    po.Status = newStatus
    po.UpdatedAt = updatedAt

    updatedPoJSON, err := json.Marshal(po)
    if err != nil {
        return fmt.Errorf("failed to marshal updated purchase order: %v", err)
    }

    return ctx.GetStub().PutState(id, updatedPoJSON)
}

// GetAllPOs returns all purchase orders found in the ledger
func (s *SmartContract) GetAllPOs(ctx contractapi.TransactionContextInterface) ([]PurchaseOrder, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var pos []PurchaseOrder

    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }

        var po PurchaseOrder
        err = json.Unmarshal(queryResponse.Value, &po)
        if err != nil {
            return nil, err
        }

        pos = append(pos, po)
    }

    return pos, nil
}

// main function starts the chaincode server when the node is executed
func main() {
    chaincode, err := contractapi.NewChaincode(new(SmartContract))
    if err != nil {
        fmt.Printf("Error creating chaincode: %s\n", err.Error())
        return
    }

    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting chaincode: %s\n", err.Error())
    }
}