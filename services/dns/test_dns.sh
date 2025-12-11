#!/usr/bin/env bash

DNS_SERVER="${DNS_SERVER:-127.0.0.1}"
DNS_PORT="${DNS_PORT:-8053}"
DOMAIN="entreprise5.lan"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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
check_a "dns"    "120.0.84.10"
check_a "radius" "120.0.84.11"
check_a "voip"   "120.0.84.12"
check_a "www"    "120.0.84.13"
check_a "vpn"    "120.0.84.14"
check_a "dhcp"   "120.0.84.15"

# Reverse tests
check_ptr "120.0.84.10" "dns.${DOMAIN}"
check_ptr "120.0.84.13" "www.${DOMAIN}"

echo "=== Summary ==="
echo -e "  ${GREEN}${ok} OK${NC}, ${RED}${fail} FAIL${NC}"

exit $(( fail > 0 ))

