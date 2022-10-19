ui            = true
api_addr      = "https://vault.teokyllc.internal:8200"
cluster_addr  = "https://vault.teokyllc.internal:8201"
disable_mlock = true

storage "azure" {
  accountName = "ataylorvaultbackend"
  accountKey  = "bn2SXyYwBo5clsJ76nXKCf5IOArL8w0MMACXVFOUG9DCOh5ov2jn2kNEB63FxU5MRq7puygLu/gz+AStZ6qN4A=="
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