#!/bin/sh
set -e
# set default value for http_api and ws_api if not exist
if [ -z ${HTTP_API+x} ]; then
  export HTTP_API="web3,eth,txpool,net,engine,debug,miner"
fi

if [ -z ${WS_API+x} ]; then
  export WS_API="web3,eth,txpool,net,engine,debug,miner"
fi

# In newer version, we need to specify the static nodes in the config file
# with "StaticNodes" instead of using the "--bootnodes" flag.
# ref: https://github.com/ethereum/go-ethereum/issues/31208
cat >/data/config.toml <<EOF
[Node.P2P]
    StaticNodes = ${GETH_STATICNODES}
EOF
echo "geth p2p bootnodes:"
cat /data/config.toml

# Disable embedded Superchain upgrade schedule so fork times from genesis.json
# are applied as-is (needed for HashKey and other non-registry custom chains).
SUPERCHAIN_UPGRADES_FLAG="--rollup.superchain-upgrades=false"

# do geth init if datadir is empty
if [ ! -d "/data/geth" ]; then
  echo "Initializing geth datadir"
  wget -O /data/genesis.json $GENESIS_URL
  geth init $SUPERCHAIN_UPGRADES_FLAG --state.scheme=hash --datadir=/data /data/genesis.json
else
  echo "geth datadir already initialized, skipping..."
fi

if [ ! -f "/data/genesis.json" ]; then
  echo "Downloading genesis.json"
  wget -O /data/genesis.json $GENESIS_URL
  geth init $SUPERCHAIN_UPGRADES_FLAG --state.scheme=hash --datadir=/data /data/genesis.json
fi

exec geth \
  --datadir=/data \
  $SUPERCHAIN_UPGRADES_FLAG \
  --rollup.disabletxpoolgossip=true \
  --rollup.sequencerhttp=$SEQUENCER_HTTP \
  --http \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=$HTTP_API \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.api=$WS_API \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.vhosts="*" \
  --authrpc.jwtsecret=/jwt/jwt.txt \
  --metrics \
  --metrics.port=6060 \
  --metrics.addr="0.0.0.0" \
  --syncmode=$GETH_SYNC_MODE \
  --gcmode=$GC_MODE \
  --config=/data/config.toml

