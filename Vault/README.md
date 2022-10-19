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

kubectl create secret docker-registry acr --docker-server=ataylorregistry.azurecr.io --docker-username=ataylorregistry --docker-password=85ojOoyJPvOumwci9X92n9+2Mwo02/2=