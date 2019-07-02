# Use an official alpine
FROM alpine:latest

MAINTAINER WUAmin <wuamin@gmail.com>

ENV LISTEN_PORT       443
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

RUN mkdir -pv /config/ssl && mkdir -p /config/ocserv

VOLUME /config/ssl
VOLUME /config/ocserv

RUN cd && \
  # Update system
  apk --update upgrade --no-cache && \
  # Install iptables
  apk --update add --no-cache iptables && \
  # Set DNSs
  echo -e "# Generated from Dockerfile\n\
  nameserver ${DNS_SERVERS1}\n\
  nameserver ${DNS_SERVERS2}\n" | sed -e 's/^\s\+//g' | tee /etc/resolv.conf && \
  # Install build dependencies packages
  apk add --no-cache --virtual .build-deps \
  curl \
  g++ \
  gpgme \
  linux-headers \
  linux-pam-dev \
  tar \
  xz \
  gettext \
  automake \
  asciidoc \
  xmlto \
  autoconf \
  build-base \
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
  lz4-dev && \
  # Download and Build ocserv
  # cd /tmp && wget "https://github.com$(curl https://github.com/openconnect/ocserv/releases | grep 'ocserv.*.tar.gz' | sed -e 's/^.*\href=\"\([^\"]*\)\".*/\1/g' | head -n 1)" -O ocserv.tar.gz && \
  cd /tmp && wget "ftp://ftp.infradead.org/pub/ocserv/ocserv-$(curl https://ocserv.gitlab.io/www/download.html | grep -i latest | grep -e '[0-9]\+\.[0-9]\+\.[0-9]\+' | sed -e 's/.*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/g').tar.xz" -O ocserv.tar.xz && \
  mkdir -pv /tmp/ocserv && tar xvf ocserv.tar.xz -C /tmp/ocserv --strip-components=1 && rm -rfv ocserv.tar.xz && cd ocserv/ && \
  # chmod +x ./autogen.sh && ./autogen.sh && ./configure --prefix=/usr/local --sysconfdir=/config/ocserv && \
  ./configure --prefix=/usr/local --sysconfdir=/config/ocserv && make && make install && cd .. && rm -rfv ocserv && cd && \
  # Remove build dependencies packages
  apk del .build-deps && \
  # Install Libs
  apk --update add --no-cache \
  lz4-libs \
  gnutls \
  libev \
  protobuf-c \
  libseccomp \
  linux-pam && \
  # Tuning system
  echo -e "\n\
  fs.file-max = 100000\n\
  net.ipv4.ip_forward=1\n\
  net.core.somaxconn = 10240\n\
  # Protect from IP Spoofing  \n\
  net.ipv4.conf.all.rp_filter = 1\n\
  net.ipv4.conf.default.rp_filter = 1\n\
  \n\
  # Ignore ICMP broadcast requests\n\
  net.ipv4.icmp_echo_ignore_broadcasts = 1\n\
  \n\
  # Protect from bad icmp error messages\n\
  net.ipv4.icmp_ignore_bogus_error_responses = 1\n\
  \n\
  # Disable source packet routing\n\
  net.ipv4.conf.all.accept_source_route = 0\n\
  net.ipv6.conf.all.accept_source_route = 0\n\
  net.ipv4.conf.default.accept_source_route = 0\n\
  net.ipv6.conf.default.accept_source_route = 0\n\
  \n\
  # Turn on exec shield\n\
  kernel.exec-shield = 1\n\
  kernel.randomize_va_space = 1\n\
  \n\
  # Block SYN attacks\n\
  net.ipv4.tcp_syncookies = 1\n\
  net.ipv4.tcp_max_syn_backlog = 2048\n\
  net.ipv4.tcp_synack_retries = 2\n\
  net.ipv4.tcp_syn_retries = 5\n\
  \n\
  # Log Martians  \n\
  net.ipv4.conf.all.log_martians = 1\n\
  net.ipv4.icmp_ignore_bogus_error_responses = 1\n\
  \n\
  # Ignore send redirects\n\
  net.ipv4.conf.all.send_redirects = 0\n\
  net.ipv4.conf.default.send_redirects = 0\n\
  \n\
  # Ignore ICMP redirects\n\
  net.ipv4.conf.all.accept_redirects = 0\n\
  net.ipv6.conf.all.accept_redirects = 0\n\
  net.ipv4.conf.default.accept_redirects = 0\n\
  net.ipv6.conf.default.accept_redirects = 0\n\
  net.ipv4.conf.all.secure_redirects = 0\n\
  net.ipv4.conf.default.secure_redirects = 0\n" | sed -e 's/^\s\+//g' | tee -a /etc/sysctl.conf && \
  sysctl -p && \
  # Iptables
  mkdir -pv /etc/iptables


COPY start.sh /config/start.sh
RUN chmod +x /config/start.sh

# Run ocserv
CMD /config/start.sh