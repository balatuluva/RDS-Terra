resource "random_password" "db_password" {
  length = 16
  special = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "db_secret_password" {
  name = "db-secret-password"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_string = random_password.db_password.result
  secret_id           = aws_secretsmanager_secret.db_secret_password.id
  #secret_name = aws_secretsmanager_secret.db_secret.name
}