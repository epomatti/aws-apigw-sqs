resource "aws_iam_role" "apigateway" {
  name = "SlackBotAPIGatewayIntegration"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "apigateway" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:SendMessage",
          "sqs:SendMessageBatch"
        ],
        "Resource" : "${var.sqs_queue_arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apigateway" {
  role       = aws_iam_role.apigateway.name
  policy_arn = aws_iam_policy.apigateway.arn
}
