#### What is it:

It's a simple and straightforward pattern of configs for web development and running small web sites with Nginx.

Sets of sample configs for other services such as PHP and MySQL will be added to other folders of this repo.

#### Task definition:

* Run Nginx in docker using same configs for production and development
* Issue and renew Let's Encript certificates in production
* Use a self-signed certificate in a local develpment environment
* Support IPv6 in production
* Health-check for Nginx service in a container in production
* A standalone solution, independent from host, cron or other services

Problems:
* Nginx can't issue ACME certificates and docker does not provide tools for periodical jobs to renew certificates
* Docker has a very bad support for IPv6
* Custom 3rd-party builds should be avoided in general

#### Solution:

1. Build the container from an official Nginx docker image.
2. Add [Acme.sh](https://github.com/acmesh-official/acme.sh) for Let's Encrypt certificates.
3. List domains for a certificate in the environment variable
4. A shell script `50-acme.sh` runs certificates issue and renewal routines.
5. In production Nginx runs in a host network mode.
6. In development environment docker-compose reads `docker-compose.override` and replaces some values thanks to YAML inheritance.
7. A demo config for Nginx to support HTTPS with IPv6 and response for healthcheck requests is provided.

#### Details on issuing and renewing certificates 

A script `50-acme.sh` mounted to `/docker-entrypoint.d/` folder in a container is executed when the container is created.
In development environment `50-acme.sh` issues just a self-signed certificate. 
In production it runs [acme.sh](https://github.com/acmesh-official/acme.sh) to issues the certificate after Nginx starts, and creates a background shell process running certificate renewal like cron wold do. 

#### Usage:

In development run with `docker-compose up -d`

In production run with `docker stack up -c docker-compose.yml mystackname`
