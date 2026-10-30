#!/usr/bin/env bash
set -euo pipefail

TOKEN_FILE="/root/.secrets/duckdns-token"

if [[ ! -r "$TOKEN_FILE" ]]; then
    echo "DuckDNS token file is missing or unreadable."
    exit 1
fi

DUCKDNS_TOKEN="$(< "$TOKEN_FILE")"

RESPONSE="$(
    curl --silent --show-error --fail --config - <<EOF
url = "https://www.duckdns.org/update"
get
data-urlencode = "domains=elevvo-lab"
data-urlencode = "token=${DUCKDNS_TOKEN}"
data-urlencode = "txt="
data-urlencode = "clear=true"
data-urlencode = "verbose=true"
EOF
)"

if [[ "$RESPONSE" != OK* ]]; then
    echo "DuckDNS TXT cleanup failed: $RESPONSE"
    exit 1
fi

echo "DuckDNS TXT cleanup response:"
printf '%s\n' "$RESPONSE"
