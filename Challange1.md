# Challenge 1

Solution to the task is in `scripts/fetchTransactionHistory.ts`

## Naive solution analysis:

The initial naive solution fetches transaction logs within a given block range from a node provider (e.g., Infura) using the standard RPC API (`eth_getLogs`) and later parses the results, looking for transactions that have the addresses we need in either the "from" or "to" field. To prevent error: too big result from RPC API, initial query is divided into several sub-queries with given blockPartition size.

This is not a performant or production-ready solution.

In one year (assuming that the average block time is 12s), there are about ~2.6M blocks.
Infura and other node providers have limits on queries to prevent overloading their services.

Limits for Infura: [link here](https://docs.infura.io/api/networks/ethereum/json-rpc-methods/eth_getlogs#constraints).
The maximum is 10,000 results and 10s for query processing.

Under these conditions, we can analyze the naive solution:
* When fetching with a chunk size of 100,000, Infura returns an error as more than 10,000 results are returned (more than 10k transaction events in the given block interval).
* When fetching with a chunk size of 50,000, it also errors out but a little later: result sizes were about (4781, 6668, ... error > 10000).
* If I were to fetch with a chunk size of 10,000, it would probably work but the number of RPC queries would be ~267 for one year (this would take a very long time).

The naive solution would not work in production as we need to consider rate limiting and the total time for the query of all transactions.

**_Note on calculating the block number X years ago:_**

There are several solutions. Two were implemented in the task:
1. Approximation - We assume that one block takes approximately 12.5s, and based on that, calculate a block number X years ago.
This approximation becomes highly inaccurate for dates > 1 year.
   
2. Use a library that makes precise calculations - It most likely uses binary search to find the block number closest to the date X years ago.
This requires multiple queries to the RPC API `eth_getBlockByNumber` and is time and resource-consuming, but it is an accurate solution.

3. An option not implemented in the solution is the usage of a specialized API from a node provider. For example, Moralis provides an endpoint [get-date-by-block](https://docs.moralis.io/web3-data-api/evm/reference/get-date-to-block?chain=eth)
that returns the closest block number with just one quick query.


## What could be improved

1. Use more enhanced RPC API

For instance, we could use Moralis and their Token API: `getTokenTransfers()` - [link here](https://docs.moralis.io/web3-data-api/evm/reference/get-token-transfers?address=0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0&chain=eth&order=DESC).

This endpoint offers several useful features:
* It supports the use of date ranges in queries - eliminating the need to calculate the block number from X years ago.
* It has built-in pagination - so manual handling of block ranges is unnecessary.

However, we would also need to consider the cost and time required for the query.

2. Use analytics engines

We could use TheGraph:

Create (or utilize an existing) subgraph to query data without the need for interaction with an RPC node provider.
With TheGraph, you can perform queries using the GraphQL API and receive responses in JSON format. It supports pagination for handling large results.
This approach should be faster and cheaper than using an RPC API, and TheGraph is likely to handle large results more effectively. 
We would still need to consider the cost of TheGraph queries on Ethereum and ensure that it remains performant for extensive ranges of data (spanning many years).
This solution should also scale well in terms of performance if we aim to gather data for more tokens.

We could use Dune Analytics:

This analytics engine allows building blockchain queries using an SQL-like language. They recently added an API, enabling you to fetch results programmatically (previously, data could only be accessed through dashboards).
Dune Analytics can handle very large queries (up to 8GB results) and is known for its performance.

Further analysis should be conducted on TheGraph and Dune to assess costs and performance; however, both are expected to scale effectively with increasing data volumes.

There are several other analytics solutions that are not mentioned here that I have not used but may also be worth exploring, such as Flipside Crypto, Nansen, Covalent, etc.

3. In-house solution

If we need to query transaction data frequently, it could be beneficial to create an in-house solution where we store transaction records in a cloud-based or self-hosted database. This database would be populated by data streaming in real-time from websockets/geysers that many RPC node providers offer. Such an approach would enable the fastest and most cost-effective queries.

On the downside, the maintenance costs could be significant. We would need to pay a cloud provider for database services and employ personnel to maintain it. Ensuring the pipeline's functionality requires building some sort of monitoring system, which might be provided by the cloud operator. Additionally, depending on the number of tokens we aim to track, we would have to assess potential scalability issues: how large our database is, and how quickly it grows.

This solution could offer the lowest cost per query and minimal latency, but it comes with high maintenance costs.

 