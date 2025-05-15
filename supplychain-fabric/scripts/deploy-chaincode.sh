#!/bin/bash

# Set environment variables for peer0.org1
export CORE_PEER_LOCALMSPID="CompanyAMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/companyA.example.com/peers/peer0.companyA.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/companyA.example.com/users/Admin@companyA.example.com/msp
export CORE_PEER_ADDRESS=peer0.companyA.example.com:7051

# Chaincode Variables
CC_NAME="procurement-chaincode"
CC_SRC_PATH="/opt/gopath/src/github.com/chaincode"
CC_LANGUAGE="golang"
CC_VERSION="1.0"
CHANNEL_NAME="ProcurementChannel"

# Packaging the chaincode
echo "Packaging chaincode..."
peer lifecycle chaincode package ${CC_NAME}.tar.gz \
  --path ${CC_SRC_PATH} \
  --lang ${CC_LANGUAGE} \
  --label ${CC_NAME}_${CC_VERSION}

# Install chaincode
echo "Installing chaincode..."
peer lifecycle chaincode install ${CC_NAME}.tar.gz

# Query installed chaincode to get package ID
echo "Querying installed chaincode..."
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep -o 'PackageID:[^,]*' | cut -d':' -f2-)

# Approve chaincode definition
echo "Approving chaincode..."
peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 \
  --channelID $CHANNEL_NAME \
  --name $CC_NAME \
  --version $CC_VERSION \
  --package-id $PACKAGE_ID \
  --sequence 1 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Commit chaincode definition
echo "Committing chaincode..."
peer lifecycle chaincode commit -o orderer.example.com:7050 \
  --channelID $CHANNEL_NAME \
  --name $CC_NAME \
  --version $CC_VERSION \
  --sequence 1 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --peerAddresses peer0.companyA.example.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/companyA.example.com/peers/peer0.companyA.example.com/tls/ca.crt

# Test invoke
echo "Invoking chaincode..."
peer chaincode invoke -o orderer.example.com:7050 \
  --isInit \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C $CHANNEL_NAME -n $CC_NAME \
  --peerAddresses peer0.companyA.example.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/companyA.example.com/peers/peer0.companyA.example.com/tls/ca.crt \
  -c '{"function":"InitLedger","Args":[]}'

echo "Chaincode deployed successfully!"