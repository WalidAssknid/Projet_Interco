#!/bin/bash
set -e
# TESTS (à completer pour les autres services.., j 'ai uniquement testé le dhcp et la connexion entre clients et ddhcp)

# Désactiver BuildKit pour utiliser l'ancien build
export DOCKER_BUILDKIT=0

# Nettoyer et relancer le projet
echo "Arrêt et nettoyage des conteneurs existants..."
docker-compose down || true

echo "Lancement des conteneurs en arrière-plan..."
docker-compose up -d

# Pause pour laisser les conteneurs démarrer
echo "Attente que les conteneurs démarrent..."
sleep 10

# vérifier que les conteneurs sont bien démarrés
echo "=== État des conteneurs ==="
docker ps

# Verifier les IP des clients
echo "=== IP des clients ==="
docker exec client1 ip addr show eth0
docker exec client2 ip addr show eth0

#Tester la communication
echo "=== Test ping entre client1 et dhcp ==="
docker exec client1 ping -c 3 dhcp

echo "=== Test ping entre client2 et dhcp ==="
docker exec client2 ping -c 3 dhcp

echo "=== Test ping entre client1 et client2 ==="
docker exec client1 ping -c 3 client2

# Fin des tests
echo "=== Test terminé ==="
