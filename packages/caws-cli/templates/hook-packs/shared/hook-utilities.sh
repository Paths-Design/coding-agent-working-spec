#!/bin/bash
# CAWS-MANAGED-HOOK
# hook_pack: shared
# hook_pack_version: 1
# caws_min_major: 11
# Optional extension. Not present in the default event chain.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/parse-input.sh"
parse_hook_input
[[ -n "${CAWS_OPTIONAL_HOOK_POLICY:-}" ]] || exit 0
python3 "$SCRIPT_DIR/lib/hook-utilities.py" "$CAWS_OPTIONAL_HOOK_POLICY"
