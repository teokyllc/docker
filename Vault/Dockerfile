# https://hub.docker.com/_/vault
FROM vault:latest

COPY config.hcl /vault/config.hcl

COPY vault.teokyllc.internal.crt /vault/vault.crt
COPY vault.teokyllc.internal.key /vault/vault.key
COPY TEOKYLLC_Root_CA.crt /vault/vault.ca.crt

ENTRYPOINT vault server -config=/vault/config.hcl