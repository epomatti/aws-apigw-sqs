# Display the SQS queue URL & API Gateway invokation URL
output "SQS-QUEUE" {
  value       = aws_sqs_queue.ec2_instance_stop_in.id
  description = "The SQS Queue URL"
}

output "APIGW-URL" {
  value       = aws_api_gateway_stage.slackbot.invoke_url
  description = "The API Gateway Invocation URL Queue URL"
}

# Command for testing to send data to api gateway
output "Test-Command1" {
  value       = "curl --location --request POST '${aws_api_gateway_stage.slackbot.invoke_url}/ec2' --header 'Content-Type: application/json'  --data-raw '{ \"TestMessage\": \"Hello From ApiGateway!\" }'"
  description = "Command to invoke the API Gateway"
}

# Command for testing to retrieve the message from the SQS queue
output "Test-Command2" {
  value       = "aws sqs receive-message --queue-url ${aws_sqs_queue.ec2_instance_stop_in.id}"
  description = "Command to query the SQS Queue for messages"
}
