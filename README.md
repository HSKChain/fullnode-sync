# HashkeyChain Fullnode Synchronization Guide

A simple docker compose script for launching full node for Hashkey Chain.

## Recommended Hardware

- 4 Core
- 16 GB+ RAM
- 1TB SSD (NVME Recommended)
- 100 MB/s+ Download

## Prepare

### Generate JWT file

```shell
openssl rand -hex 32 > ./jwt/jwt.txt
```

### Copy .env.example to .env and update the value

Make a copy of `.env.example.testnet` named `.env`.

```sh
cp .env.example.testnet .env
# modify .env to your parameters.
```

Or, our team will provide one `.env` file for your rollup directly.

## Operating the Node

### Start

```sh
docker compose --env-file .env up -d
```

### View logs

logs for op node

```sh
docker compose logs -f node
```

logs for op geth

```sh
docker compose logs -f geth
```

### Sanity Test

#### check sync status

```sh
curl --location 'localhost:8545' \
--header 'Content-Type: application/json' \
--data '{
  "jsonrpc": "2.0",
  "method": "eth_syncing",
  "param": [],
  "id": 2
}'
```

if the node is still syncing, you would see:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "currentBlock": "0x7d0f5",
    "healedBytecodeBytes": "0x0",
    "healedBytecodes": "0x0",
    "healedTrienodeBytes": "0x9d12b",
    "healedTrienodes": "0x1197",
    "healingBytecode": "0x0",
    "healingTrienodes": "0x0",
    "highestBlock": "0xd8674",
    "startingBlock": "0x6a58f",
    "syncedAccountBytes": "0xb1801",
    "syncedAccounts": "0x9c1",
    "syncedBytecodeBytes": "0x51375",
    "syncedBytecodes": "0x34",
    "syncedStorage": "0x2b24",
    "syncedStorageBytes": "0x225f7a"
  }
}
```

or the syncing has completed:

```json
{"jsonrpc":"2.0","id":2,"result":false}
```

#### check after syncing

```sh
curl --location 'localhost:8545' \
--header 'Content-Type: application/json' \
--data '{
  "jsonrpc": "2.0",
  "method": "eth_blockNumber",
  "id": 2
}'
```

should return something like:

```sh
{
    "jsonrpc": "2.0",
    "id": 2,
    "result": "0x2139"
}
```

### Stop

```sh
docker compose down
```

### Hardfork / config upgrade

When the network upgrades and `genesis.json` / `rollup.json` change:

1. Update images and config URLs in `.env` if needed. **Before running `upgrade.sh`, `NODE_IMAGE` must be set to:**
   ```sh
   NODE_IMAGE=public.ecr.aws/x7e7q5l8/op-node:v1.16.5
   ```
   Also update `GETH_IMAGE` when a new op-geth version is required.
2. Pull new images yourself if the tags changed:
   ```sh
   docker compose --env-file .env pull
   ```
3. Run the upgrade helper (deletes cached configs and restarts; does **not** wipe chain data):
   ```sh
   chmod +x ./upgrade.sh   # first time only
   ./upgrade.sh
   ```

The script removes `/data/genesis.json` and `/data/rollup.json` from the service volumes, then restarts. Entrypoints will re-download the configs and re-run `geth init` so fork schedule updates are written into the local chain config.

### Reference

- <https://docs.optimism.io/builders/node-operators/tutorials/node-from-docker>
