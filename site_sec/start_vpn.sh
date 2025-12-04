#!/bin/sh
# Simule le réseau local distant
ip addr add 192.168.5.1/24 dev eth0

# Clé privée (correspondant à la PubKey du routeur AS5)
echo "8H5f5X5f5X5f5X5f5X5f5X5f5X5f5X5f5X5f5X5f5X4=" > /etc/wireguard/private.key

cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $(cat /etc/wireguard/private.key)
Address = 10.5.5.2/30
ListenPort = 51820

[Peer]
# Clé Publique de R_AS5 (calculée à l'avance)
PublicKey = Mz+J+J+J+J+J+J+J+J+J+J+J+J+J+J+J+J+J+J+J+J0=
AllowedIPs = 120.0.80.0/20
Endpoint = 172.20.0.254:51820
PersistentKeepalive = 25
EOF

ip link add dev wg0 type wireguard
wg setconf wg0 /etc/wireguard/wg0.conf
ip link set up dev wg0
tail -f /dev/null
