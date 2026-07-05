#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEOS="${THEOS:-/Users/nono/theos}"

cd "$ROOT"
THEOS="$THEOS" make package

