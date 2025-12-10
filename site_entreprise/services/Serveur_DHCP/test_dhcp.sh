#!/bin/bash

set -e  # Arrêter le script en cas d'erreur

SERVER="Serveur_DHCP"
CLIENT1="Client1"
CLIENT2="Client2"
NETWORK="Reseau_Test"
SERVER_IP="120.0.80.7"
SUBNET="120.0.80.0/24"

echo "=== Nettoyage des anciens conteneurs et réseaux ==="
docker rm -f $SERVER $CLIENT1 $CLIENT2 2>/dev/null || true
docker network rm $NETWORK 2>/dev/null || true

echo "=== Création du réseau de test ==="
docker network create --subnet=$SUBNET $NETWORK || echo "Le réseau existe déjà"

echo "=== Construction et lancement du serveur DHCP ==="
docker build -t dhcp-server-image .
docker run -d --rm --name $SERVER --net $NETWORK --ip $SERVER_IP dhcp-server-image

sleep 5  # Laisser le serveur DHCP démarrer

echo "=== Lancement des clients de test ==="
for CLIENT in $CLIENT1 $CLIENT2; do
    docker run -dit --rm --name $CLIENT --net $NETWORK --cap-add=NET_ADMIN --privileged ubuntu:latest bash
    echo "=== Installation des outils DHCP sur $CLIENT ==="
    docker exec -e DEBIAN_FRONTEND=noninteractive $CLIENT bash -c "apt-get update && apt-get install -y isc-dhcp-client iproute2"
    echo "=== Demande d'adresse DHCP pour $CLIENT ==="
    docker exec $CLIENT dhclient eth0
    docker exec $CLIENT ip addr show eth0
done

echo "=== Test terminé ==="

