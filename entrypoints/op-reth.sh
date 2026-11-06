#!/bin/sh
set -e

# engine API is only served on authrpc; do not include it in http/ws api lists
if [ -z "${HTTP_API+x}" ]; then
  HTTP_API="web3,eth,net"
fi

if [ -z "${WS_API+x}" ]; then
  WS_API="web3,eth,net"
fi

# full = pruned full node; archive = keep full history (op-reth default)
if [ -z "${RETH_MODE+x}" ] || [ -z "$RETH_MODE" ]; then
  RETH_MODE="full"
fi

if [ ! -f /config/genesis.json ]; then
  echo "error: /config/genesis.json missing. Run ./fetch-config.sh on the host first."
  exit 1
fi

# Keep a writable copy in the datadir for inspection / upgrades.
cp /config/genesis.json /data/genesis.json

EXTRA_ARGS=""
case "$RETH_MODE" in
  full)
    echo "RETH_MODE=full (pruned)"
    EXTRA_ARGS="$EXTRA_ARGS --full"
    ;;
  archive)
    echo "RETH_MODE=archive"
    ;;
  *)
    echo "error: RETH_MODE must be 'full' or 'archive', got: $RETH_MODE"
    exit 1
    ;;
esac

if [ -n "${RETH_TRUSTED_PEERS:-}" ]; then
  echo "Using trusted peers"
  EXTRA_ARGS="$EXTRA_ARGS --trusted-peers=${RETH_TRUSTED_PEERS}"
fi

# shellcheck disable=SC2086
exec /usr/local/bin/op-reth node \
  --chain=/data/genesis.json \
  --datadir=/data \
  --http \
  --http.corsdomain='*' \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api="${HTTP_API}" \
  --ws \
  --ws.origins='*' \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.api="${WS_API}" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=/jwt/jwt.txt \
  --metrics=0.0.0.0:9001 \
  --rollup.disable-tx-pool-gossip \
  --rollup.sequencer-http="${SEQUENCER_HTTP}" \
  $EXTRA_ARGS
