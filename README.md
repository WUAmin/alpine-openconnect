# alpine-openconnect
openconnect server (ocserv) for Docker


## Build a docker image
```bash
git clone https://github.com/WUAmin/alpine-openconnect.git
cd alpine-openconnect/
docker build --tag=alpine-openconnect .
```

---


## Run docker container
You have to specify two paths, `ocserv config` and `ssl folder` as mounting volumes.



### **ocserv Config**
This folder will be used to generate:
Files | Description | Replace `*
--- | --- | ---
**`ocserv.conf`** | ocserv config | `NO`
**`ocpasswd`** | Contain user credentials | `NO`
**`rules.v4`** | iptables rules | `NO`

`*` Replace means if files exist, they won't be replaced. So you can put your config or firewall rules there.



### **SSL Folder**
This folder will be used to provide SSL files to the container and should contain 3 files for private, public and CA file for your ssl. You need to provide filename with `SERVER_CERT_NAME`, `SERVER_KEY_NAME` and `SERVER_CA_NAME` variables.
You can use [certbot](https://certbot.eff.org/) to get a free [Let's Encrypt](https://letsencrypt.org/) SSL.

**NOTE: `both mounting volumes and valid SSL files are necessary`.**



Here is an example:
```bash
mkdir -pv ~/alpine-openconnect-1_config/ ~/ssl/
docker run -d --privileged \
	-v ~/alpine-openconnect-1_config/:/config/ocserv \
	-v ~/ssl/:/config/ssl \
  -e LISTEN_PORT=2443 \
  -e SERVER_CERT_NAME=cert1.pem \
  -e SERVER_KEY_NAME=privkey1.pem \
  -e SERVER_CA_NAME=fullchain1.pem \
  -e IPV4_NET=192.168.11.0 \
  -p 2443:2443 \
  --name alpine-openconnect-1 \
  --hostname alpine-openconnect-1 \
  --restart always \
  alpine-openconnect /bin/sh
```

---


## Use docker-compose (optional)
You can also use [docker-compose](https://github.com/docker/compose) to manage docker containers.
This is a simple example of a `docker-compose.yml` file.
```yaml
alpine-openconnect-1:
  image: alpine-openconnect
  container_name: alpine-openconnect-1
  ports:
    - "443:443"
  volumes:
    - ~/alpine-openconnect-1_config/:/config/ocserv
    - ~/ssl/:/config/ssl
  environment:
    - LISTEN_PORT=443
    - DNS_SERVERS1=8.8.8.8
    - DNS_SERVERS2=1.1.1.1
    - SERVER_CERT_NAME=cert1.pem
    - SERVER_KEY_NAME=privkey1.pem
    - SERVER_CA_NAME=fullchain1.pem
    - MAX_CLIENTS=16
    - MAX_SAME_CLIENTS=1
    - DEVICE_NAME=vpns
    - DEFAULT_DOMAIN=example.com
    - IPV4_NET=192.168.10.0
    - IPV4_MASK=255.255.255.0
  restart: always
```
and run your docker-compose.yml file:
```bash
git clone https://github.com/WUAmin/alpine-openconnect.git
cd alpine-openconnect/
mkdir -pv ~/alpine-openconnect-1_config/ ~/ssl/
docker-compose up -d
docker-compose ps
```
