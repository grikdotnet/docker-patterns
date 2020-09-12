#### What is it:

It's a pattern of configs for web development and running small web sites with Nginx.

Sets with other services such as PHP and MySQL can be found in other folders in this repo.

#### Task definition:

* Run Nginx using same configs for production and development
* Issue and renew Let's Encript certificates in production
* Use a self-signed certificate in a local develpment environment
* Support IPv6 in production
* Health-check for Nginx service in a container in production

Problems:
* Nginx can't issue ACME certificates
* Docker has a very bad support for IPv6
* Custom 3rd-party builds should be avoided in general

#### Solution:

1. Build the container from an official Nginx docker image.
2. A shell script `50-acmesh` mounted to th `/docker-entrypoint.d/` folder is executed when the container is created.  
3. In production Nginx runs in a host network. 
3. In development environment docker-compose reads `docker-compose.override` and overrides some values due to YAML inheritance
4. A demo config for Nginx to support HTTPS with IPv6 and response for healthcheck requests

#### Usage:

In development run with `docker-compose up -d`

In production run with `docker stack up -c docker-compose`
