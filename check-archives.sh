#!/usr/bin/env bash
# Verify that all data-archive URLs in index.html are available on the Wayback Machine.
# Exits with code 1 if any URL returns a non-2xx status.

set -euo pipefail

FAIL=0

# Extract all data-archive URLs from index.html
urls=$(grep -oP 'data-archive="\K[^"]+' index.html)

for url in $urls; do
    status=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 30 "$url") || status="000"

    if [[ "$status" =~ ^2 ]]; then
        echo "OK   $status  $url"
    else
        echo "FAIL $status  $url"
        FAIL=1
    fi
done

if [ "$FAIL" -eq 1 ]; then
    echo ""
    echo "Some archive URLs are not available."
    exit 1
else
    echo ""
    echo "All archive URLs are available."
fi
