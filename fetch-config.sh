#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT_DIR"

if [ ! -f .env ]; then
  echo "error: .env not found. Copy .env.example.testnet or .env.example.mainnet to .env first."
  exit 1
fi

# shellcheck disable=SC1091
set -a
# shellcheck source=/dev/null
. ./.env
set +a

if [ -z "${GENESIS_URL:-}" ] || [ -z "${ROLLUP_CONFIG_URL:-}" ]; then
  echo "error: GENESIS_URL and ROLLUP_CONFIG_URL must be set in .env"
  exit 1
fi

mkdir -p config

echo "Downloading genesis.json from $GENESIS_URL"
curl -fsSL -o config/genesis.json "$GENESIS_URL"

echo "Downloading rollup.json from $ROLLUP_CONFIG_URL"
curl -fsSL -o config/rollup.json "$ROLLUP_CONFIG_URL"

echo "Configs ready:"
ls -lh config/genesis.json config/rollup.json
