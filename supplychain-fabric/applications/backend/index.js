const { Gateway } = require("fabric-network");
const path = require("path");
const fs = require("fs");

async function main() {
  const ccpPath = path.resolve(__dirname, "connection.json");
  const ccp = JSON.parse(fs.readFileSync(ccpPath, "utf8"));

  const wallet = await Wallets.newFileSystemWallet("./wallet"); // identities stored here

  const gateway = new Gateway();
  await gateway.connect(ccp, {
    wallet,
    identity: "user1",
    discovery: { enabled: true, asLocalhost: true },
  });

  const network = await gateway.getNetwork("ProcurementChannel");
  const contract = network.getContract("procurement-chaincode");

  const result = await contract.evaluateTransaction("GetPO", "PO123");
  console.log(`Result: ${result.toString()}`);
}

main();
