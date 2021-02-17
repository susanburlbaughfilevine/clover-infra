# Call template_file data source for Lambda Function
# https://www.terraform.io/docs/configuration/functions/templatefile.html
data "template_file" "cloudwatch_alarm_lambda" {
  template = file("./cloudwatch_alarm_lambda.py")
  vars = {
    slack_channel_name = var.slack_channel_name
    slack_webhook      = var.slack_webhook
  }
}

# https://www.terraform.io/docs/providers/archive/d/archive_file.html
# Archive index.js file to .zip
data "archive_file" "slack_lmf_archive" {
  type        = "zip"
  output_path = "./${var.envName}-slack-lmf.zip"

  source {
    content  = data.template_file.cloudwatch_alarm_lambda.rendered
    filename = "cloudwatch_alarm_lambda.py"
  }
}

# Create IAM Role & Role Policy for Lambda Assume Role and Execution
# https://www.terraform.io/docs/providers/aws/r/iam_role_policy.html
resource "aws_iam_role_policy" "lambda_basic_execution_policy" {
  name   = "${var.envName}-clover-lambda_basic_execution_policy"
  role   = aws_iam_role.lambda_basic_execution_role.id
  policy = data.aws_iam_policy_document.lambda_basic_execution_policy.json
}

data "aws_iam_policy_document" "lambda_basic_execution_policy" {
  statement {
    sid = "AllowLogging"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/*:*"]
  }

  statement {
    sid = "AllowLogGroupCreate"
    actions = [
      "logs:CreateLogGroup"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role" "lambda_basic_execution_role" {
  name               = "${var.envName}-clover-lambda_basic_execution_role"
  assume_role_policy = data.aws_iam_policy_document.sts-lambda_basic_execution_policy.json
}

data "aws_iam_policy_document" "sts-lambda_basic_execution_policy" {
  statement {
    sid     = "AllowAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

# Create Lambda Function
# https://www.terraform.io/docs/providers/aws/r/lambda_function.html
resource "aws_lambda_function" "sns_slack_lmf" {
  filename         = "${var.envName}-slack-lmf.zip"
  function_name    = "${var.envName}-clover-slack-function"
  source_code_hash = filebase64sha256("${var.envName}-slack-lmf.zip")
  role             = aws_iam_role.lambda_basic_execution_role.arn
  handler          = "cloudwatch_alarm_lambda.lambda_handler"
  runtime          = "python3.8"
  environment {
    variables = {
      SLACK_CHANNEL = var.slack_channel_name
      HOOK_URL      = var.slack_webhook
    }
  }

}

# Grant SNS Permission to perform actions on Lambda Functions
# https://www.terraform.io/docs/providers/aws/r/lambda_permission.html
resource "aws_lambda_permission" "sns_slack_lmf_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_slack_lmf.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.slack_sns_topic.arn
}

resource "aws_lambda_permission" "allow_sns_lmf_permission" {
  statement_id  = "Allow_SNS_Access"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_slack_lmf.function_name
  principal     = "sns.amazonaws.com"
  // source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:High-Cpu-Utilization"
}
