FROM alpine:latest
RUN apk add --no-cache wireguard-tools iptables
COPY start_vpn.sh /start_vpn.sh
RUN chmod +x /start_vpn.sh
ENTRYPOINT ["/start_vpn.sh"]
