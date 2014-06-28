# Change this to suit your needs.
NAME=docker-dnscrypt-wrapper
USERNAME=mengbo
RESOLVER_ADDRESS=8.8.8.8
RESOLVER_PORT=53
LISTEN_PORT=443
PROVIDER_NAME=2.dnscrypt-cert.yourdomain.com

BASEDIR=/usr/local/share/dnscrypt-wrapper

DOCKER_PORT=-p $(LISTEN_PORT):$(LISTEN_PORT) -p $(LISTEN_PORT):$(LISTEN_PORT)/udp

DOCKER_VOLUME=-v $(BASEDIR):$(BASEDIR)

DOCKER_RUN_ENV=-e RESOLVER_ADDRESS="$(RESOLVER_ADDRESS)" \
               -e RESOLVER_PORT="$(RESOLVER_PORT)" \
               -e LISTEN_PORT="$(LISTEN_PORT)" \
               -e PROVIDER_NAME="$(PROVIDER_NAME)"

TEST=$(NAME)-test

RUNNING:=$(shell docker ps | grep $(NAME) | cut -f 1 -d ' ')
ALL:=$(shell docker ps -a | grep $(NAME) | cut -f 1 -d ' ')

PROVIDER_KEY:=$(shell grep fingerprint $(BASEDIR)/provider_keypair.txt | sed 's/.*: //')

all: build

build:
	docker build -t $(USERNAME)/$(NAME) .

run: clean
	docker run --name $(NAME) -d \
		$(DOCKER_PORT) $(DOCKER_VOLUME) $(DOCKER_RUN_ENV) $(USERNAME)/$(NAME)

bash: clean
	docker run --name $(NAME) -t -i \
		$(DOCKER_PORT) $(DOCKER_VOLUME) $(DOCKER_RUN_ENV) $(USERNAME)/$(NAME) \
		/bin/bash

test: run
	sleep 5
	docker run --name $(TEST) -d --link $(NAME):provider \
		-p 53:53 -p 53:53/udp mengbo/docker-dnscrypt \
		/bin/bash -c "dnscrypt-proxy -a 0.0.0.0:53 \
		-r \$$PROVIDER_PORT_$(LISTEN_PORT)_TCP_ADDR:$(LISTEN_PORT) \
		--provider-name=$(PROVIDER_NAME) \
		--provider-key=$(PROVIDER_KEY)"
	sleep 5
	dig @127.0.0.1 google.com

# Removes existing containers.
clean:
ifneq ($(strip $(RUNNING)),)
	docker stop $(RUNNING)
endif
ifneq ($(strip $(ALL)),)
	docker rm $(ALL)
endif
