terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  account = data.aws_caller_identity.current.account_id
}

resource "aws_api_gateway_rest_api" "slackbot" {
  name        = "slackbot"
  description = "Endpoints for the AWS Slack Bot automations."

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "slackbot" {
  rest_api_id = aws_api_gateway_rest_api.slackbot.id
}

resource "aws_cloudwatch_log_group" "default" {
  name_prefix = "/aws/APIGW/terraform"
}

resource "aws_api_gateway_stage" "slackbot" {
  deployment_id = aws_api_gateway_deployment.slackbot.id
  rest_api_id   = aws_api_gateway_rest_api.slackbot.id
  stage_name    = "default"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.default.arn
    format          = file("${path.module}/accessLogFormat.json")
  }

  lifecycle {
    ignore_changes = [deployment_id]
  }
}

resource "aws_api_gateway_method_settings" "default" {
  rest_api_id = aws_api_gateway_rest_api.slackbot.id
  stage_name  = aws_api_gateway_stage.slackbot.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_resource" "ec2" {
  rest_api_id = aws_api_gateway_rest_api.slackbot.id
  parent_id   = aws_api_gateway_rest_api.slackbot.root_resource_id
  path_part   = "ec2"
}

resource "aws_api_gateway_method" "ec2_post" {
  rest_api_id   = aws_api_gateway_rest_api.slackbot.id
  resource_id   = aws_api_gateway_resource.ec2.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.slackbot.id
  resource_id = aws_api_gateway_resource.ec2.id
  http_method = aws_api_gateway_method.ec2_post.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.slackbot.id
  resource_id = aws_api_gateway_resource.ec2.id
  http_method = aws_api_gateway_method.ec2_post.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
}

resource "aws_sqs_queue" "ec2_instance_stop_in" {
  name = "ec2-instance-stop-in"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.slackbot.id
  resource_id             = aws_api_gateway_resource.ec2.id
  http_method             = aws_api_gateway_method.ec2_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${local.account}/${aws_sqs_queue.ec2_instance_stop_in.name}"
  credentials             = module.iam_sqs.role_arn

  passthrough_behavior = "NEVER"
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }
  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

### SQS Integration Role ###

module "iam_sqs" {
  source        = "./modules/iam-sqs"
  sqs_queue_arn = aws_sqs_queue.ec2_instance_stop_in.arn
}

### CloudWatch ###

resource "aws_api_gateway_account" "ApiGatewayAccountSetting" {
  cloudwatch_role_arn = module.iam_logs.role_arn
}

module "iam_logs" {
  source = "./modules/iam-logs"
}

