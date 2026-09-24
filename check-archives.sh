#!/usr/bin/env bash
# Verify that all data-archive URLs in index.html are available on the Wayback Machine.
# Exits with code 1 if any URL returns a non-2xx status.

set -euo pipefail

FAIL=0

# Extract all data-archive URLs from index.html
urls=$(grep -oP 'data-archive="\K[^"]+' index.html)

for url in $urls; do
    # The Wayback Machine is slow to resolve bare (undated) snapshot URLs and
    # rate-limits bursts, so allow generous time and retry transient failures.
    # A real 404 still comes back as a status and fails the check.
    # Some snapshots occasionally time out outright (curl status 000) rather
    # than answering with an HTTP code, so retry the whole request a few
    # times on top of curl's own per-request retries.
    for attempt in 1 2 3; do
        status=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 90 \
            --retry 3 --retry-delay 5 --retry-all-errors "$url") || status="000"
        [[ "$status" =~ ^2 ]] && break
        sleep 10
    done
    sleep 2

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
