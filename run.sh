#!/bin/bash

RESOLVER_ADDRESS=${RESOLVER_ADDRESS:="8.8.8.8"}
RESOLVER_PORT=${RESOLVER_PORT:-"53"}
LISTEN_ADDRESS=${LISTEN_ADDRESS:-"0.0.0.0"}
LISTEN_PORT=${LISTEN_PORT:-"443"}
PROVIDER_NAME=${PROVIDER_NAME:-"2.dnscrypt-cert.yourdomain.com"}


cd /usr/local/share/dnscrypt-wrapper

[ ! -f public.key ] && [ ! -f secret.key ] && \
	dnscrypt-wrapper --gen-provider-keypair | tee provider_keypair.txt

[ ! -f crypt_public.key ] && [ ! -f crypt_secret.key ] && \
	dnscrypt-wrapper --gen-crypt-keypair | tee crypt_keypair.txt

[ ! -f dnscrypt.cert ] && \
	dnscrypt-wrapper \
	--crypt-publickey-file=crypt_public.key \
	--crypt-secretkey-file=crypt_secret.key \
	--provider-publickey-file=public.key \
	--provider-secretkey-file=secret.key \
	--gen-cert-file | tee cert_file.txt

dnscrypt-wrapper  -r ${RESOLVER_ADDRESS}:${RESOLVER_PORT} \
	-a ${LISTEN_ADDRESS}:${LISTEN_PORT} \
	--crypt-publickey-file=crypt_public.key \
       	--crypt-secretkey-file=crypt_secret.key \
	--provider-cert-file=dnscrypt.cert \
	--provider-name=${PROVIDER_NAME} \
	-VV
