#!/bin/bash

# Set environment variables
CHANNEL_NAME="ProcurementChannel"
DELAY=3
CCP_PATH="${PWD}/configtx"
ORG_MSP="CompanyAMSP" # Org that will create the channel

export FABRIC_CFG_PATH=${CCP_PATH}

echo "====> Generating genesis block for Orderer <===="
configtxgen -profile MultiOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
if [ $? -ne 0 ]; then
    echo "Failed to generate genesis block!"
    exit 1
fi

echo "====> Generating channel.tx for $CHANNEL_NAME <===="
configtxgen -profile MultiOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
if [ $? -ne 0 ]; then
    echo "Failed to generate channel transaction!"
    exit 1
fi

echo "====> Generating anchor peer update for CompanyA <===="
configtxgen -profile MultiOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/CompanyAAnchors.tx -asOrg CompanyA -channelID $CHANNEL_NAME
if [ $? -ne 0 ]; then
    echo "Failed to generate anchor peer update for CompanyA!"
    exit 1
fi

echo "====> Starting Docker network <===="
docker-compose up -d
sleep $DELAY

# Set environment for peer CLI
export CORE_PEER_LOCALMSPID="CompanyAMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/crypto-config/peerOrganizations/companyA.example.com/peers/peer0.companyA.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/companyA.example.com/users/Admin@companyA.example.com/msp
export CORE_PEER_ADDRESS=peer0.companyA.example.com:7051
export ORDERER_CA=${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo "====> Creating channel '$CHANNEL_NAME' <===="
peer channel create -o orderer.example.com:7050 \
                    -c $CHANNEL_NAME \
                    --tls --cafile $ORDERER_CA \
                    -f ./channel-artifacts/channel.tx
if [ $? -ne 0 ]; then
    echo "Failed to create channel!"
    exit 1
fi

echo "====> Joining peer0.companyA.example.com to channel <===="
peer channel join -b ${CHANNEL_NAME}.block
if [ $? -ne 0 ]; then
    echo "Failed to join channel!"
    exit 1
fi

echo "====> Updating anchor peers for CompanyA <===="
peer channel update -o orderer.example.com:7050 \
                    -c $CHANNEL_NAME \
                    -f ./channel-artifacts/CompanyAAnchors.tx \
                    --tls --cafile $ORDERER_CA
if [ $? -ne 0 ]; then
    echo "Failed to update anchor peer!"
    exit 1
fi

echo "✅ Channel '$CHANNEL_NAME' created and peer0.companyA joined successfully."