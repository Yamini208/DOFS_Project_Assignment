resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "dlq_lambda_exec" {
  name = "dlq-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_step_function_policy" {
  name        = "LambdaStepFunctionPolicy"
  description = "Allows Lambda to start Step Function execution"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "states:StartExecution",
        Resource = "arn:aws:states:us-east-1:934787941896:stateMachine:order-orchestrator"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_step_function_attach" {
  name       = "lambda-step-function-attach"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = aws_iam_policy.lambda_step_function_policy.arn
}

resource "aws_iam_policy" "lambda_dynamodb_access" {
  name = "lambda-dynamodb-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:934787941896:table/orders"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach_dynamodb" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamodb_access.arn
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda-sqs-policy"
  description = "Allow Lambda to read messages from SQS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.order_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_sqs_access" {
  name = "lambda-sqs-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = [
          aws_sqs_queue.order_queue.arn,
          aws_sqs_queue.order_dlq.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

resource "aws_iam_role_policy" "dlq_lambda_policy" {
  name = "dlq-lambda-policy"
  role = aws_iam_role.dlq_lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.order_dlq.arn
      },
      {
        Effect = "Allow",
        Action = "dynamodb:PutItem",
        Resource = module.dynamodb.failed_orders_table_arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_sqs_dlq_policy" {
  name        = "lambda-sqs-dlq-policy"
  description = "Allow Lambda to send messages to DLQ"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sqs:SendMessage",
        Resource = aws_sqs_queue.order_dlq.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dlq_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_dlq_policy.arn
}

module "api_handler_lambda" {
  source         = "./modules/lambdas"
  function_name  = "api-handler"
  handler        = "main.lambda_handler"
  runtime        = "python3.9"
  filename       = "${path.module}/../lambdas/api_handler/lambda.zip"
  role_arn       = aws_iam_role.lambda_exec.arn
  environment_variables = {
    SFN_ARN = aws_sfn_state_machine.order_orchestrator.arn
  }
}

# Validator Lambda
module "validator_lambda" {
  source         = "./modules/lambdas"
  function_name  = "validator"
  handler        = "main.lambda_handler"
  runtime        = "python3.9"
  filename       = "${path.module}/../lambdas/validator/lambda.zip"
  role_arn       = aws_iam_role.lambda_exec.arn
}

# Order Storage Lambda
module "order_storage_lambda" {
  source         = "./modules/lambdas"
  function_name  = "order-storage"
  handler        = "main.lambda_handler"
  runtime        = "python3.9"
  filename       = "${path.module}/../lambdas/order_storage/lambda.zip"
  role_arn       = aws_iam_role.lambda_exec.arn
  environment_variables = {
    ORDER_TABLE = module.dynamodb.orders_table_name
  }
}

# Fulfill Order Lambda
module "fulfill_order_lambda" {
  source         = "./modules/lambdas"
  function_name  = "fulfill-order"
  handler        = "main.lambda_handler"
  runtime        = "python3.9"
  filename       = "${path.module}/../lambdas/fulfill_order/lambda.zip"
  role_arn       = aws_iam_role.lambda_exec.arn
  environment_variables = {
    ORDER_TABLE = module.dynamodb.orders_table_name
  }
}

module "dlq_handler_lambda" {
  source         = "./modules/lambdas"
  function_name  = "dlq-handler"
  handler        = "main.lambda_handler"
  runtime        = "python3.9"
  filename       = "${path.module}/../lambdas/dlq_handler/lambda.zip"
  role_arn       = aws_iam_role.dlq_lambda_exec.arn

  environment_variables = {
    FAILED_TABLE = module.dynamodb.failed_orders_table_name
  }
}

# --- API Gateway ---
resource "aws_apigatewayv2_api" "http_api" {
  name          = "order-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.api_handler_lambda.lambda_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_order" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /order"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.api_handler_lambda.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}


resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.order_queue.arn
  function_name    = module.fulfill_order_lambda.lambda_name
  batch_size       = 1
}

resource "aws_lambda_event_source_mapping" "dlq_trigger" {
  event_source_arn = aws_sqs_queue.order_dlq.arn
  function_name    = module.dlq_handler_lambda.lambda_name
  batch_size       = 1
}

resource "aws_sqs_queue" "order_dlq" {
  name = "order_dlq"
}

resource "aws_sqs_queue" "order_queue" {
  name = "order_queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_dlq.arn
    maxReceiveCount     = 3
  })
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

output "debug_orders_table_name" {
  value = module.dynamodb.orders_table_name
}
