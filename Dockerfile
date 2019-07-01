# Use an official alpine
FROM alpine:latest

ENV LISTEN_PORT       2443
ENV DNS_SERVERS1      8.8.8.8
ENV DNS_SERVERS2      1.1.1.1
ENV SERVER_CERT_NAME  cert1.pem
ENV SERVER_KEY_NAME   privkey1.pem
ENV SERVER_CA_NAME    fullchain1.pem
ENV MAX_CLIENTS       16
ENV MAX_SAME_CLIENTS  1
ENV DEVICE_NAME       vpns
ENV DEFAULT_DOMAIN    example.com
ENV IPV4_NET          192.168.11.0
ENV IPV4_MASK         255.255.255.0



# Install iptables & restore rules
RUN apk --update add --no-cache iptables

# Set DNSs
RUN echo "nameserver ${DNS_SERVERS1} \n\
  nameserver ${DNS_SERVERS2}" | tee /etc/resolv.conf

# Install build dependencies packages
RUN apk add --no-cache --virtual .build-deps \
  pkgconf \
  gawk \
  make \
  cmake \
  g++ \
  pkgconf \
  gnutls-dev \
  libseccomp-dev \
  readline-dev \
  libnl3-dev \
  libevdev \
  libev \
  protobuf-c-dev \
  protobuf \
  gnutls \
  git \
  libev-dev \
  lz4-dev

# Build ocserv
RUN wget ftp://ftp.infradead.org/pub/ocserv/ocserv-0.12.3.tar.xz
RUN tar xf ocserv-0.12.3.tar.xz
RUN cd ocserv-0.12.3 && \
  ./configure --prefix=/usr/local --sysconfdir=/etc && \
  make && \
  make install && \
  cd .. && \
  rm -rf ocserv-0.12.3

# Remove build dependencies packages
RUN cd;apk del .build-deps

# Install Libs
RUN apk --update add --no-cache \
  lz4-libs \
  gnutls \
  libev \
  protobuf-c \
  libseccomp

# Generate start.sh script
RUN mkdir -p /app && \
  echo -e '#!/bin/bash \n\
  \n\
  echo "*nat \n\
  :PREROUTING ACCEPT [0:0] \n\
  :INPUT ACCEPT [0:0] \n\
  :OUTPUT ACCEPT [0:0] \n\
  :POSTROUTING ACCEPT [0:0] \n\
  -A POSTROUTING -j MASQUERADE \n\
  COMMIT \n\
  *filter \n\
  :INPUT ACCEPT [0:0] \n\
  :FORWARD ACCEPT [0:0] \n\
  :OUTPUT ACCEPT [0:0] \n\
  COMMIT \n\
  " | tee /etc/iptables/rules.v4 \n\
  iptables-restore < /etc/iptables/rules.v4 \n\
  \n\
  echo "auth = \"plain[/config/ocpasswd]\" \n\
  tcp-port = ${LISTEN_PORT} \n\
  udp-port = ${LISTEN_PORT} \n\
  run-as-user = nobody \n\
  run-as-group = daemon \n\
  socket-file = /var/run/ocserv-socket \n\
  server-cert = /config/certs/${SERVER_CERT_NAME} \n\
  server-key = /config/certs/${SERVER_KEY_NAME} \n\
  ca-cert = /config/certs/${SERVER_CA_NAME} \n\
  isolate-workers = true \n\
  max-clients = ${MAX_CLIENTS} \n\
  max-same-clients = ${MAX_SAME_CLIENTS} \n\
  keepalive = 32400 \n\
  dpd = 90 \n\
  compression = true \n\
  mobile-dpd = 1800 \n\
  cert-user-oid = 0.9.2342.19200300.100.1.1 \n\
  tls-priorities = \"NORMAL:%SERVER_PRECEDENCE:%COMPAT:-VERS-SSL3.0\" \n\
  auth-timeout = 240 \n\
  min-reauth-time = 3 \n\
  max-ban-score = 50 \n\
  ban-reset-time = 300 \n\
  cookie-timeout = 300 \n\
  deny-roaming = false \n\
  rekey-time = 172800 \n\
  rekey-method = ssl \n\
  use-utmp = true \n\
  use-occtl = true \n\
  pid-file = /var/run/ocserv.pid \n\
  device = ${DEVICE_NAME} \n\
  predictable-ips = true \n\
  default-domain = ${DEFAULT_DOMAIN} \n\
  ipv4-network = ${IPV4_NET} \n\
  ipv4-netmask = ${IPV4_MASK} \n\
  dns = ${DNS_SERVERS1} \n\
  dns = ${DNS_SERVERS2} \n\
  ping-leases = false \n\
  cisco-client-compat = true \n\
  dtls-legacy = true \n\" | tee /config/ocserv.conf \n\
  \n\
  touch /config/ocpasswd \n\
  \n\
  echo " \n\
  fs.file-max = 100000 \n\
  net.ipv4.ip_forward=1 \n\
  net.core.somaxconn = 10240" | tee -a /etc/sysctl.conf \n\
  sysctl -p \n\
  echo \n\
  echo \n\
  echo "Running OpenConnect Server..." \n\
  ocserv -c /config/ocserv.conf -f \n\
  ' | tee /app/start.sh && \
  chmod +x /app/start.sh


# Run ocserv
CMD ["/bin/sh", "/app/start.sh"]