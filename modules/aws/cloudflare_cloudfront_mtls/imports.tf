# Adopt pre-existing Secrets Manager secrets (e.g. after state loss or manual creation).
# Empty for_each yields no import actions. IDs are the secret names accepted by the AWS provider.
locals {
  secretsmanager_secret_import_root_ca = (
    var.create && var.import_existing_secretsmanager_secrets
    ? { this = "${local.secret_name_stem}/root-ca" }
    : {}
  )
  secretsmanager_secret_import_client = (
    var.create && var.import_existing_secretsmanager_secrets
    ? { this = "${local.secret_name_stem}/client-cert" }
    : {}
  )
}

import {
  for_each = local.secretsmanager_secret_import_root_ca
  to       = aws_secretsmanager_secret.root_ca[0]
  id       = each.value
}

import {
  for_each = local.secretsmanager_secret_import_client
  to       = aws_secretsmanager_secret.client[0]
  id       = each.value
}
