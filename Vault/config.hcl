ui            = true
api_addr      = "https://127.0.0.1:8200"
cluster_addr  = "https://127.0.0.1:8201"
disable_mlock = true

storage "azure" {
  accountName = "ataylorvaultbackend"
  accountKey  = ""
  container   = "vault"
  environment = "AzurePublicCloud"
}

listener "tcp" {
  address            = "0.0.0.0:8200"
  tls_disable        = "false"
  tls_cert_file      = "/vault/vault.crt"
  tls_key_file       = "/vault/vault.key"
  tls_client_ca_file = "/vault/vault.ca.crt"
}