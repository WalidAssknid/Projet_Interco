FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Installer Bind9 et outils DNS
RUN apt-get update && \
    apt-get install -y bind9 bind9utils dnsutils && \
    rm -rf /var/lib/apt/lists/*

# Copier la config BIND dans le conteneur
COPY named.conf /etc/bind/named.conf
COPY zone_ent5 /etc/bind/zone_ent5
COPY db.192.168.10 /etc/bind/db.192.168.10
# Répertoire de cache utilisé par Bind
RUN mkdir -p /var/cache/bind

# Ouvrir le port DNS
EXPOSE 53/udp 53/tcp

# Lancer Bind9 au premier plan (mode "daemonless" pour Docker)
CMD ["named", "-g", "-c", "/etc/bind/named.conf"]

