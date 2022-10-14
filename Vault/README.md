# docker-hashi-vault
A Docker image project for Hashicorp Vault
<br><br>

<b>Build</b><br>

```
docker build -t vault:latest .
```

<br><br>

<b>Init the vault</b><br>

```
docker run --name vault-0 --network host -d vault:latest
docker exec -it vault-0 vault operator init -tls-skip-verify
```

<br><br>

<b>Unseal the vault</b><br>

```
docker run -d vault:latest 
```