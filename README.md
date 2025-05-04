# Development environment docker images

This repo contains the Dockerfile for building the build environment.
In addition, this repo also contain files for hosting a Docker registry server.

Looking for?

- [Installing scripts as users](#installation)
- [Building a new container](/container/README.md)
- [Hosting a server](/server/README.md)

# Installation

You can run this command for one liner installation without git clone.

```
su -c "bash <(curl -s -L https://raw.github.hpe.com/craig-yang/XXXXXX)"
```

# Example Usages

<TODO>

# Config docker proxy

1. Create the directory if not present

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
```

2. Edit /etc/systemd/system/docker.service.d/proxy.conf

```bash
[Service]
Environment="HTTP_PROXY={ADDRESS}[:PORT]" "NO_PROXY=localhost,127.0.0.1"
Environment="HTTPS_PROXY={ADDRESS}[:PORT]" "NO_PROXY=localhost,127.0.0.1"
```

3. Ask module to reload configs and restart the service to take effect

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## Helpful links

- [Insecure way to froce docker using http](https://docs.docker.com/registry/insecure/).
