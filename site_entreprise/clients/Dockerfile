# ---- Dockerfile pour les clients ----

FROM ubuntu:22.04

# Évite les dialogues pendant l'installation des paquets
ENV DEBIAN_FRONTEND=noninteractive

# Installer les outils réseau et ping
RUN apt-get update && \
    apt-get install -y iproute2 isc-dhcp-client iputils-ping net-tools curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Définir un nom d'hôte par défaut (modifiable via ARG)
ARG CLIENT_NAME=client
RUN echo $CLIENT_NAME > /etc/hostname

# Lancer un shell par défaut pour tester les commandes
CMD ["bash", "-c"]
