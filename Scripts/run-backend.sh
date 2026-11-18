#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../Backend"
export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-8080}"
swift run
