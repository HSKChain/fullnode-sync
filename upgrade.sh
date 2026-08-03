#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT_DIR"

COMPOSE="docker compose --env-file .env"

if [ ! -f .env ]; then
  echo "error: .env not found. Copy .env.example.testnet to .env and update values first."
  exit 1
fi

echo "This will:"
echo "  1. stop geth and node"
echo "  2. delete /data/genesis.json from the geth volume"
echo "  3. delete /data/rollup.json from the node volume"
echo "  4. restart services so configs are re-downloaded and geth re-inits chain config"
echo
echo "It will NOT pull images, change .env, or wipe chain data volumes."
echo "Update GETH_IMAGE / NODE_IMAGE (and config URLs) in .env before running this."
echo
printf "Continue? [y/N] "
read -r answer
case "$answer" in
  y|Y|yes|YES) ;;
  *)
    echo "Aborted."
    exit 0
    ;;
esac

echo "Stopping services..."
$COMPOSE stop

echo "Removing genesis.json from geth volume..."
$COMPOSE run --rm --no-deps --entrypoint sh geth -c 'rm -f /data/genesis.json && echo "removed /data/genesis.json (or already absent)"'

echo "Removing rollup.json from node volume..."
$COMPOSE run --rm --no-deps --entrypoint sh node -c 'rm -f /data/rollup.json && echo "removed /data/rollup.json (or already absent)"'

echo "Starting services..."
$COMPOSE up -d

echo
echo "Upgrade restart complete. Check logs:"
echo "  docker compose --env-file .env logs -f geth"
echo "  docker compose --env-file .env logs -f node"
