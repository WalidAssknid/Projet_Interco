#!/bin/bash

# Nom de l'image et du conteneur
IMAGE_NAME="image_serveur_dhcp"
CONTAINER_NAME="Serveur_DHCP"

# Construire l'image Docker depuis le dossier courant
echo "Construction de l'image Docker..."
docker build -t $IMAGE_NAME .

# Vérifier si un conteneur avec le même nom existe et le supprimer
if [ $(docker ps -a -q -f name=$CONTAINER_NAME) ]; then
    echo "Suppression de l'ancien conteneur..."
    docker rm -f $CONTAINER_NAME
fi

# Lancer le conteneur
echo "Lancement du conteneur..."
docker run -tid --name $CONTAINER_NAME --cap-add=NET_ADMIN $IMAGE_NAME

# Créer le fichier des leases et démarrer le serveur DHCP dans le conteneur
echo "Initialisation du serveur DHCP..."
docker exec $CONTAINER_NAME touch /var/lib/dhcp/dhcpd.leases
docker exec $CONTAINER_NAME dhcpd

# Afficher les logs pour vérifier que tout fonctionne
echo "Logs du serveur DHCP :"

