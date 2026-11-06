#!/bin/sh
set -e

export OP_NODE_L1_ETH_RPC=$L1_RPC
export OP_NODE_L1_RPC_KIND=$L1_RPC_KIND
export OP_NODE_P2P_STATIC=$P2P_STATIC
export OP_NODE_L1_BEACON=$L1_BEACON
export OP_NODE_VERIFIER_L1_CONFS=15
export OP_NODE_SEQUENCER_L1_CONFS=15
export ROLLUP_CONFIG_URL=$ROLLUP_CONFIG_URL

export OP_NODE_ALTDA_DA_SERVICE=$ALTDA_DA_SERVICE
export OP_NODE_ALTDA_ENABLED=$ALTDA_ENABLED
if [ -n "$PLASMA_ENABLED" ] && [ ! -n "$ALTDA_ENABLED" ]; then
  echo "PLASMA_ENABLED is set, ALTDA_ENABLED is not set ,use PLASMA_ENABLED as OP_NODE_ALTDA_ENABLED"
  export OP_NODE_ALTDA_ENABLED=$PLASMA_ENABLED
fi
echo "OP_NODE_ALTDA_ENABLED: $OP_NODE_ALTDA_ENABLED"

export OP_NODE_ALTDA_DA_SERVER=$ALTDA_DA_SERVER
if [ -n "$PLASMA_DA_SERVER" ] && [ ! -n "$ALTDA_DA_SERVER" ]; then
  echo "PLASMA_DA_SERVER is set, ALTDA_DA_SERVER is not set ,use PLASMA_DA_SERVER as OP_NODE_ALTDA_DA_SERVER"
  export OP_NODE_ALTDA_DA_SERVER=$PLASMA_DA_SERVER
fi
echo "OP_NODE_ALTDA_DA_SERVER: $OP_NODE_ALTDA_DA_SERVER"

if [ ! -f /config/rollup.json ]; then
  echo "error: /config/rollup.json missing. Run ./fetch-config.sh on the host first."
  exit 1
fi

cp /config/rollup.json /data/rollup.json

mkdir -p /data/opnode_discovery_db
mkdir -p /data/opnode_peerstore_db
mkdir -p /data/safedb

# op-node retries engine dials; give reth a short head start.
echo "Waiting briefly for reth engine..."
sleep 5

exec op-node \
  --safedb.path=/data/safedb \
  --rollup.config=/data/rollup.json \
  --syncmode=execution-layer \
  --l1=$L1_RPC \
  --l1.beacon=$L1_BEACON \
  --l1.trustrpc \
  --l2=http://reth:8551 \
  --l2.jwt-secret=/jwt/jwt.txt \
  --l2.enginekind=reth \
  --metrics.enabled \
  --metrics.port=7300 \
  --metrics.addr="0.0.0.0" \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \
  --p2p.listen.ip=0.0.0.0 \
  --p2p.listen.tcp=9003 \
  --p2p.listen.udp=9003 \
  --p2p.discovery.path=/data/opnode_discovery_db \
  --p2p.peerstore.path=/data/opnode_peerstore_db \
  --p2p.priv.path=/data/opnode_p2p_priv.txt
