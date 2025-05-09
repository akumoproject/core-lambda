resource "aws_iam_role" "eventbridge_invoker" {
  name = "eventbridge-invoker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name    = "eventbridge-invoker-role"
    Purpose = "Trigger Lambda from EventBridge"
    EID     = "4004"
    Project = "project11"
    Env     = "shs"
    IaC     = "Terraform"
    Ou      = "infra"
  }
}
resource "aws_iam_policy" "eventbridge_lambda_invoke" {
  name = "eventbridge-invoke-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = data.aws_lambda_function.check_tags.arn
      }
    ]
  })
  tags = {
    Name    = "eventbridge-invoker-role"
    Purpose = "Trigger Lambda from EventBridge"
    EID     = "4004"
    Project = "project11"
    Env     = "shs"
    IaC     = "Terraform"
    Ou      = "infra"
  }
}

resource "aws_iam_role_policy_attachment" "attach_eventbridge_invoke_policy" {
  role       = aws_iam_role.eventbridge_invoker.name
  policy_arn = aws_iam_policy.eventbridge_lambda_invoke.arn
}



#EventBridge Rule
resource "aws_cloudwatch_event_rule" "resource_creation" {
  name        = "resource-creation-rule"
  description = "Trigger on AWS API Create events"

  event_pattern = jsonencode({
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventName" : [
        "RunInstances",
        "CreateBucket",
        "CreateFunction",
        "CreateTable",
        "CreateDBInstance",
        "CreateLoadBalancer"
      ],
      "eventSource" : [
        "ec2.amazonaws.com",
        "s3.amazonaws.com",
        "lambda.amazonaws.com",
        "dynamodb.amazonaws.com",
        "rds.amazonaws.com",
        "elasticloadbalancing.amazonaws.com"
      ]
    }
  })
  tags = {
    Name    = "eventbridge-invoker-role"
    Purpose = "Trigger Lambda from EventBridge"
    EID     = "4004"
    Project = "project11"
    Env     = "shs"
    IaC     = "Terraform"
    Ou      = "infra"
  }
}
data "aws_lambda_function" "check_tags" {
  function_name = "infra-shs-demo-lambda-tag"
}

# 5. EventBridge Target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.resource_creation.name
  target_id = "check-tags"
  arn       = "arn:aws:lambda:us-east-1:439143907190:function:infra-shs-demo-lambda-tag"
  role_arn  = aws_iam_role.eventbridge_invoker.arn
}

# 6. Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.check_tags.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.resource_creation.arn
}
