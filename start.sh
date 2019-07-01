#!/bin/bash

echo "*nat
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
COMMIT
" | tee /etc/iptables/rules.v4
iptables-restore < /etc/iptables/rules.v4

echo "auth = \"plain[/config/ocpasswd]\"
tcp-port = ${LISTEN_PORT}
udp-port = ${LISTEN_PORT}
run-as-user = nobody
run-as-group = daemon
socket-file = /var/run/ocserv-socket
server-cert = /config/certs/${SERVER_CERT_NAME}
server-key = /config/certs/${SERVER_KEY_NAME}
ca-cert = /config/certs/${SERVER_CA_NAME}
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
dtls-legacy = true" | tee /config/ocserv.conf

touch /config/ocpasswd

echo "
fs.file-max = 100000
net.ipv4.ip_forward=1
net.core.somaxconn = 10240" | tee -a /etc/sysctl.conf
sysctl -p
echo
echo
echo "Running OpenConnect Server..."
ocserv -c /config/ocserv.conf -f
