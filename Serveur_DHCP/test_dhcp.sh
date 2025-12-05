#!/bin/bash

SERVER="Serveur_DHCP"
CLIENT1="Client1"
CLIENT2="Client2"
NETWORK="Reseau_Test"
SERVER_IP="192.168.100.254"
SUBNET="192.168.100.0/24"

echo "=== Nettoyage des anciens conteneurs et réseaux ==="
docker rm -f $SERVER $CLIENT1 $CLIENT2 2>/dev/null
docker network rm $NETWORK 2>/dev/null

echo "=== Création du réseau de test ==="
docker network create --subnet=$SUBNET $NETWORK

echo "=== Lancement du serveur DHCP ==="
docker run -d --rm --name $SERVER --net $NETWORK --ip $SERVER_IP dhcp-server-image

sleep 5

echo "=== Lancement des clients de test ==="
for CLIENT in $CLIENT1 $CLIENT2; do
    docker run -dit --rm --name $CLIENT --net $NETWORK --cap-add=NET_ADMIN --privileged ubuntu:latest bash
    docker exec $CLIENT apt-get update
    docker exec $CLIENT DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-client iproute2
    docker exec $CLIENT dhclient eth0
done

echo "=== Test terminé ==="
