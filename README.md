# HashkeyChain Fullnode Synchronization Guide

A simple docker compose script for launching a HashKey Chain full node with **op-reth** + **op-node**.

> op-geth has reached end-of-support and is no longer used by this repository.

## Recommended Hardware

- 4 Core
- 16 GB+ RAM
- 500GB+ SSD for full (pruned) node / 1TB+ SSD for archive (NVME Recommended)
- 100 MB/s+ Download

## Prepare

### Generate JWT file

```shell
openssl rand -hex 32 > ./jwt/jwt.txt
```

### Copy env example to `.env` and update values

Testnet:

```sh
cp .env.example.testnet .env
```

Mainnet:

```sh
cp .env.example.mainnet .env
```

Then fill in `L1_RPC` and `L1_BEACON`.

### Fetch genesis / rollup configs

op-reth and op-node images are minimal and do not ship download tools, so configs are fetched on the host:

```sh
chmod +x ./fetch-config.sh
./fetch-config.sh
```

Or, our team will provide one `.env` file for your rollup directly.

Key knobs:

- `RETH_IMAGE` / `NODE_IMAGE` — execution and consensus client images
- `RETH_MODE=full|archive` — `full` enables `--full` (pruned); `archive` keeps full history
- `RETH_TRUSTED_PEERS` — comma-separated enode URLs
- `GENESIS_URL` / `ROLLUP_CONFIG_URL` — chain config downloads

## Operating the Node

### Start

```sh
docker compose --env-file .env up -d
```

### View logs

op-node:

```sh
docker compose logs -f node
```

op-reth:

```sh
docker compose logs -f reth
```

### Sanity Test

#### check sync status

```sh
curl --location 'localhost:8545' \
--header 'Content-Type: application/json' \
--data '{
  "jsonrpc": "2.0",
  "method": "eth_syncing",
  "params": [],
  "id": 2
}'
```

If the node is still syncing you will see sync progress fields; when caught up:

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

### Stop

```sh
docker compose down
```

### Hardfork / config upgrade

When the network upgrades and `genesis.json` / `rollup.json` change:

1. Update `RETH_IMAGE`, `NODE_IMAGE`, and config URLs in `.env` if needed. Current recommended images:
   ```sh
   RETH_IMAGE=us-docker.pkg.dev/oplabs-tools-artifacts/images/op-reth:v2.8.1
   NODE_IMAGE=us-docker.pkg.dev/oplabs-tools-artifacts/images/op-node:v1.19.11
   ```
2. Pull new images if the tags changed:
   ```sh
   docker compose --env-file .env pull
   ```
3. Run the upgrade helper (deletes cached configs and restarts; does **not** wipe chain data):
   ```sh
   chmod +x ./upgrade.sh   # first time only
   ./upgrade.sh
   ```

The script re-runs `./fetch-config.sh` and restarts. Entrypoints copy `./config/*.json` into the service datadirs. Unlike op-geth, op-reth does not need a separate `init` step — it loads `--chain` from genesis on startup.

### Syncing from a Snapshot

Official archive snapshots (op-reth):

```sh
# Mainnet
curl -fL -o mainnet-reth-archive-chaindata.tar.zst \
  "$(curl -fsSL https://snapshot.hashkeychain.net/mainnet/reth/latest.txt)"

# Testnet
curl -fL -o testnet-reth-archive-chaindata.tar.zst \
  "$(curl -fsSL https://snapshot.hashkeychain.net/testnet/reth/latest.txt)"
```

Stop the stack, extract into the `reth` data directory (inspect the archive layout first), set `RETH_MODE=archive` if using an archive snapshot, then `docker compose up -d`.

### Migrating from op-geth

op-geth datadir is **not** compatible with op-reth. Start a fresh `reth` volume (or restore an op-reth snapshot). Old `geth` compose volumes can be removed after cutover:

```sh
docker compose --env-file .env down
docker volume ls | grep -E 'geth|reth'
# remove obsolete geth volume only after you no longer need it
```

### Reference

- <https://docs.optimism.io/operators/node-operators/tutorials/node-from-docker>
- <https://docs.hskchain.net/docs/Build-on-HashKey-Chain/RPC-Node-Provider>
