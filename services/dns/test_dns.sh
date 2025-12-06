#!/usr/bin/env bash

# DNS test script for ent5

DNS_SERVER="${DNS_SERVER:-127.0.0.1}"
DNS_PORT="${DNS_PORT:-8053}"
DOMAIN="ent5.local"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ok=0
fail=0

check_a() {
    local name="$1"
    local expected="$2"
    echo "Testing A record for ${name}.${DOMAIN} (expected ${expected})"
    local result
    result=$(dig @"$DNS_SERVER" -p "$DNS_PORT" +short "${name}.${DOMAIN}" 2>/dev/null)

    if [[ "$result" == "$expected" ]]; then
        echo -e "  ${GREEN}OK${NC}: got ${result}"
        ok=$((ok+1))
    else
        echo -e "  ${RED}FAIL${NC}: got '${result}'"
        fail=$((fail+1))
    fi
    echo
}

check_ptr() {
    local ip="$1"
    local expected="$2"
    echo "Testing PTR record for ${ip} (expected ${expected})"
    local result
    result=$(dig @"$DNS_SERVER" -p "$DNS_PORT" +short -x "$ip" 2>/dev/null)

    if [[ "$result" == "${expected}." ]]; then
        echo -e "  ${GREEN}OK${NC}: got ${result}"
        ok=$((ok+1))
    else
        echo -e "  ${RED}FAIL${NC}: got '${result}'"
        fail=$((fail+1))
    fi
    echo
}

echo "=== Testing DNS server ${DNS_SERVER} port ${DNS_PORT} for domain ${DOMAIN} ==="
echo

# Forward tests
check_a "dns"   "192.168.10.10"
check_a "voip"  "192.168.10.20"
check_a "auth"  "192.168.10.30"
check_a "www"   "192.168.10.40"
check_a "files" "192.168.10.50"
check_a "vpn"   "192.168.10.60"

# Reverse tests (adapt if needed)
check_ptr "192.168.10.10" "dns.${DOMAIN}"
check_ptr "192.168.10.40" "www.${DOMAIN}"

echo "=== Summary ==="
echo -e "  ${GREEN}${ok} OK${NC}, ${RED}${fail} FAIL${NC}"

if [[ "$fail" -gt 0 ]]; then
    exit 1
else
    exit 0
fi

