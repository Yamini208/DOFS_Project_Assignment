resource "aws_sfn_state_machine" "order_orchestrator" {
  name     = "order-orchestrator"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    Comment = "Distributed Order Fulfillment",
    StartAt = "Validate Order",
    States = {
      "Validate Order" = {
        Type     = "Task",
        Resource = module.validator_lambda.lambda_arn,
        Next     = "Store Order"
      },
      "Store Order" = {
        Type     = "Task",
        Resource = module.order_storage_lambda.lambda_arn,
        Next     = "Fulfill Order"
      },
      "Fulfill Order" = {
        Type     = "Task",
        Resource = module.fulfill_order_lambda.lambda_arn,
        End      = true
      }
    }
  })
}

resource "aws_iam_role" "sfn_role" {
  name = "StepFunctionsExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sfn_policy" {
  name = "AllowLambdaInvoke"
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction"
        ],
        Effect   = "Allow",
        Resource = [
          module.validator_lambda.lambda_arn,
          module.order_storage_lambda.lambda_arn,
          module.fulfill_order_lambda.lambda_arn
        ]
      }
    ]
  })
}
