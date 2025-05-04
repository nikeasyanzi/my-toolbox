# Host a docker registry
1. Update `docker-compose.yml` to fit your needs of placing container data and certs directory.
2. Prepare the certificate in `certs` directory by running `./genkey.sh`
3. Run `docker-compose up` to start the service.

The registry data/blobs will be stored in `./data` which is created automatically.

## Adding certificate of self-hosted docker registry
Official document is [here](https://docs.docker.com/engine/security/certificates/)

1. Download `certs/domain.crt` from server to your local machine.
2. Copy the file to `/etc/docker/certs.d/{Docker server IP}/domain.crt`

