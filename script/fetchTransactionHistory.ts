import { BigNumber, ethers } from 'ethers';
import  'ethereum-block-by-date';
// import * as moment from 'moment';
import moment from 'moment'

const EthDater = require('ethereum-block-by-date') as any;


// Define the manual ABI inline for the function signatures you're interested in
const contractABI = [
  "function admin() view returns (address)",
  "function counterValue() view returns (uint256)",
  "function increment() public",
  "function addUserToWhitelist(address) public",
  "function removeUserFromWhiteList(address) public",
  "event Transfer(address indexed src, address indexed dst, uint256 val)"
];

interface TransferTransaction {
  from: string;
  to: string;
  value: string;
  transactionHash: string;
  blockNumber: number;
}

// Define the contract address
const contractAddress = '0x3506424f91fd33084466f402d5d97f05f8e3b4af'; // CHZ on Ethereum main-net

// Define the network you want to connect to (e.g., Mainnet, Ropsten, a local Ethereum node, etc.)
const provider = new ethers.providers.JsonRpcProvider('https://mainnet.infura.io/v3/5e51ff14ecd24a7faf37b5311c4bd61e');

const tokenContract = new ethers.Contract(contractAddress, contractABI, provider);

// Interested addresses
const interestedAddresses: string[] = [
  '0xE1BDE795EEEA71344922D46065E5ab60C9DB8448',
  '0xd8438dC4d196D1492639Cd9a94FdE7cfCf54d58D',
  '0xAB6032a62AcB21cd55B6e4CFe98d97ACD3B0FDC8'
];

// Create a set for faster address lookups
const addressSet: Set<string> = new Set(interestedAddresses);

// this is just an simple approximation
// for precise value binary search should be implemented additionally
async function getBlockNumberFromPastApprox(yearsAgo: number): Promise<number> {
  const currentBlockNumber = await provider.getBlockNumber();
  const currentBlock = await provider.getBlock(currentBlockNumber);
  const currentTimestamp = currentBlock.timestamp;

  const secondsInOneYear = 365 * 24 * 60 * 60; // Leap years included
  const averageBlockTime = 12; // Average block time in seconds

  const blocksPerYear = secondsInOneYear / averageBlockTime;
  const blocksAgo = blocksPerYear * yearsAgo;

  // Approximate start block
  const startBlock = Math.max(currentBlockNumber - Math.round(blocksAgo), 0);

  const oldBlock = await provider.getBlock(startBlock);

  const date = new Date(oldBlock.timestamp * 1000); // Convert seconds to milliseconds
  console.log("Date:", date.toString());
  console.log("Block:", startBlock);

  return startBlock;
}

// gives accurate result but takes time to return value
async function getBlockNumberFromPast(yearsAgo: number): Promise<number> {
  const dater = new EthDater(provider);

  const dateYearsAgo = moment().subtract(yearsAgo, 'years'); 

  let blockData = await dater.getDate(dateYearsAgo);
  console.log("date years ago:", dateYearsAgo);
  console.log("blockData.block", blockData.block);  

  return blockData.block;
}

async function getTransferEvents(fromBlock: number, toBlock: number, addresses: Set<string>): Promise<TransferTransaction[]> {
    try {
      console.log(`Fetch events between blocks: ${fromBlock} : ${toBlock}`);
        
      const logs = await tokenContract.queryFilter(tokenContract.filters.Transfer(), fromBlock, toBlock);
      console.log("Events amount: ", logs.length);

      // Decode and filter logs to only include events related to the interested addresses
      const transfers = logs
          .filter((log) => log.args && (addresses.has(log.args.src) || addresses.has(log.args.dst)))
          .map((log) => ({
              from: log.args!.src,
              to: log.args!.dst,
              value: log.args!.val.toString(),
              transactionHash: log.transactionHash,
              blockNumber: log.blockNumber,
          } as TransferTransaction));

      // console.log(transfers);
      return transfers;
    } catch (error) {
        console.error('Error getting transfer events:', error);
        return [];
    }
}

async function getTransferEventsByChunks(fromBlock: number, chunkSize: number, addresses: Set<string>): Promise<TransferTransaction[]> {
  const transfers: TransferTransaction[] = [];
  let startBlock = fromBlock;
  const currentBlockNumber = await provider.getBlockNumber();

  while (startBlock < currentBlockNumber) {
    let endBlock = Math.min(startBlock + chunkSize, currentBlockNumber);
    let transferEvents = await getTransferEvents(startBlock, endBlock, addresses);
    transfers.push(...transferEvents);
    startBlock = endBlock + 1;
  }
  
  return transfers;
}

async function fetchTransactionHistory(yearsAgo: number, blockPartitionSize: number, addresses: Set<string>) {
    
  /** Code according to task specification - it will take very long to execute **/
  // let oldBlockNumber = await getBlockNumberFromPast(yearsAgo);
  const oldBlockNumber = await getBlockNumberFromPastApprox(yearsAgo);
  const transfers =  await getTransferEventsByChunks(oldBlockNumber, blockPartitionSize, addresses);

  /** Test implementation with smaller time frame (20_000) blocks ago **/
  // const currentBlockNumber = await provider.getBlockNumber();
  // const transfers =  await getTransferEventsByChunks(currentBlockNumber - 20_000, blockPartitionSize, addresses);

  console.log("\n-------")
  console.log("Transfer results size: ", transfers.length);
  console.log("Transfers : ", transfers);
  }
  

fetchTransactionHistory(1, 10_000, addressSet);