resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy" "ec2_secrets_policy" {
    name = "log-app-secrets-policy"

  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = [
          for secret in aws_secretsmanager_secret.database :
          secret.arn
        ]
      }
    ]
  })
 
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "log-app-ec2-profile"

  role = aws_iam_role.ec2_role.name
}