#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT_DIR"

COMPOSE="docker compose --env-file .env"

if [ ! -f .env ]; then
  echo "error: .env not found. Copy .env.example.testnet or .env.example.mainnet to .env and update values first."
  exit 1
fi

echo "This will:"
echo "  1. re-download genesis.json / rollup.json into ./config"
echo "  2. stop reth and node"
echo "  3. restart services with the new configs"
echo
echo "It will NOT pull images, change .env, or wipe chain data volumes."
echo "Update RETH_IMAGE / NODE_IMAGE (and config URLs) in .env before running this."
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

echo "Fetching configs..."
./fetch-config.sh

echo "Stopping services..."
$COMPOSE stop

echo "Starting services..."
$COMPOSE up -d

echo
echo "Upgrade restart complete. Check logs:"
echo "  docker compose --env-file .env logs -f reth"
echo "  docker compose --env-file .env logs -f node"
