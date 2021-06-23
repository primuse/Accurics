output "ci_access_key_id" {
  value = aws_iam_access_key.ci_iam_user_credentials.id
}

output "ci_secret_access_key" {
  value = aws_iam_access_key.ci_iam_user_credentials.secret
}
