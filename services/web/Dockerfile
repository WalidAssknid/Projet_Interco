# Use Ubuntu base
FROM ubuntu:22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update & install Apache and other utilities
RUN apt-get update && \
    apt-get -y install apache2 iptables iproute2 net-tools telnet nano iputils-ping tcpdump traceroute && \
    apt-get clean

# Optional: suppress Apache ServerName warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

COPY index.html /var/www/html/index.html

# Make script executable
RUN chmod +x /home/S_WEB.sh

# Expose web server port
EXPOSE 80

# Run your script, then start Apache in foreground
CMD ["/bin/bash", "-c", "/home/S_WEB.sh && apache2ctl -D FOREGROUND"]
