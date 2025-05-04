#!/bin/bash

# Parse the IP address of the first non-local interface
ip_addr=$(ip addr show scope global | grep -Po 'inet \K[\d.]+' | head -n 1)
[[ "$ip_addr" != *.*.*.* ]] && echo "Cannot fetch IP address" && exit 1

echo -e "Generating Certificate with IP: \033[1;32m${ip_addr}\033[0;00m"
echo -e "\n\nThis certificate is bound with host IP address."
echo -e "If the IP changed, please re-generate a new one and publish to users.\n"

openssl req -newkey rsa:4096 -x509 -days 3650 -nodes -new -sha256 \
  -keyout ./certs/domain.key \
  -out ./certs/domain.crt \
  -subj "/C=TW/ST=CA/O=CraigMac./CN=CraigMac" \
  -reqexts SAN -extensions SAN \
  -config \
  <(cat /etc/ssl/openssl.cnf)
