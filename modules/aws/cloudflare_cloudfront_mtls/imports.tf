# Adopt pre-existing Secrets Manager secrets (e.g. after state loss or manual creation).
# Empty for_each yields no import actions. Import id must be the secret ARN (AWS provider v6+).
locals {
  secretsmanager_secret_import_root_ca = (
    var.create && var.import_existing_secretsmanager_secrets
    ? { this = data.aws_secretsmanager_secret.import_root_ca[0].arn }
    : {}
  )
  secretsmanager_secret_import_client = (
    var.create && var.import_existing_secretsmanager_secrets
    ? { this = data.aws_secretsmanager_secret.import_client_cert[0].arn }
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
