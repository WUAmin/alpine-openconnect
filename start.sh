#!/bin/sh

if [ -f "/config/ocserv/rules.v4" ]; then
  echo "Use existing iptables rules."
else
  echo "Generating iptables rules..."
  echo -e "*nat
    :PREROUTING ACCEPT [0:0]
    :INPUT ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :POSTROUTING ACCEPT [0:0]
    -A POSTROUTING -j MASQUERADE
    COMMIT
    *filter
    :INPUT ACCEPT [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    -A INPUT -p udp -m udp --dport 137 -j DROP
    -A INPUT -p tcp -m tcp --dport 137 -j DROP
    -A INPUT -p udp -m udp --dport 138 -j DROP
    -A INPUT -p tcp -m tcp --dport 138 -j DROP
    -A INPUT -p udp -m udp --dport 139 -j DROP
    -A INPUT -p tcp -m tcp --dport 139 -j DROP
    -A INPUT -p udp -m udp --dport 445 -j DROP
    -A INPUT -p tcp -m tcp --dport 445 -j DROP
    COMMIT
    " | sed -e 's/^\s\+//g' > /config/ocserv/rules.v4
fi
iptables-restore < /config/ocserv/rules.v4

if [ -f "/config/ocserv/ocserv.conf" ]; then
  echo "Use existing ocserv config."
else
  echo "Generating ocserv config..."
  echo "auth = \"plain[/config/ocserv/ocpasswd]\"
    tcp-port = ${LISTEN_PORT}
    udp-port = ${LISTEN_PORT}
    run-as-user = nobody
    run-as-group = daemon
    socket-file = /var/run/ocserv-socket
    server-cert = /config/ssl/${SERVER_CERT_NAME}
    server-key = /config/ssl/${SERVER_KEY_NAME}
    ca-cert = /config/ssl/${SERVER_CA_NAME}
    isolate-workers = true
    max-clients = ${MAX_CLIENTS}
    max-same-clients = ${MAX_SAME_CLIENTS}
    keepalive = 32400
    dpd = 90
    mobile-dpd = 1800
    cert-user-oid = 0.9.2342.19200300.100.1.1
    tls-priorities = \"NORMAL:%SERVER_PRECEDENCE:%COMPAT:-VERS-SSL3.0\"
    auth-timeout = 240
    min-reauth-time = 3
    max-ban-score = 50
    ban-reset-time = 300
    cookie-timeout = 300
    deny-roaming = false
    rekey-time = 172800
    rekey-method = ssl
    use-utmp = true
    use-occtl = true
    pid-file = /var/run/ocserv.pid
    device = ${DEVICE_NAME}
    predictable-ips = true
    default-domain = ${DEFAULT_DOMAIN}
    ipv4-network = ${IPV4_NET}
    ipv4-netmask = ${IPV4_MASK}
    dns = ${DNS_SERVERS1}
    dns = ${DNS_SERVERS2}
    ping-leases = false
    cisco-client-compat = true
    dtls-legacy = true
    " | sed -e 's/^\s\+//g' > /config/ocserv/ocserv.conf
fi

touch /config/ocserv/ocpasswd

echo
echo
echo "Running OpenConnect Server..."
ocserv -c /config/ocserv/ocserv.conf -f
