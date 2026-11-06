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

# Download to local /tmp first, then move into place.
# Direct -o into cloud-synced dirs (e.g. ~/cloud/...) often fails with:
#   curl: (23) client returned ERROR on write of ...
download_to() {
  url="$1"
  dest="$2"
  tmp=$(mktemp "${TMPDIR:-/tmp}/fullnode-sync.XXXXXX")
  # shellcheck disable=SC2064
  trap 'rm -f "$tmp"' EXIT
  echo "Downloading $(basename "$dest") from $url"
  curl -fL --retry 3 --retry-delay 2 --connect-timeout 30 -o "$tmp" "$url"
  mv -f "$tmp" "$dest"
  trap - EXIT
}

download_to "$GENESIS_URL" config/genesis.json
download_to "$ROLLUP_CONFIG_URL" config/rollup.json

echo "Configs ready:"
ls -lh config/genesis.json config/rollup.json
