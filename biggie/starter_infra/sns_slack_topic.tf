# Create SNS Topic
# https://www.terraform.io/docs/providers/aws/r/sns_topic.html
resource "aws_sns_topic" "slack_sns_topic" {
  name         = "${var.envName}-clover-slack-alerting"
  display_name = "${var.envName}-clover-slack-alerting"
  policy       = <<POLICY
{
  "Version":  "2012-10-17",
  "Statement": [
    {
      "Sid": "slack_sns_topic_policy",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:Publish",
        "SNS:Receive"
      ],
      "Resource": "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.envName}-slack-alerting",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "${data.aws_caller_identity.current.account_id}"
        }
      }
    }
  ]
}
  POLICY

  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "numRetries": 3,
      "numNoDelayRetries": 0,
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numMinDelayRetries": 0,
      "numMaxDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false
  }
}
EOF
}

## Create SNS Topic Subscription for Lambda
# https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html
resource "aws_sns_topic_subscription" "slack_lmf_sns_topic_subscription" {
  topic_arn = aws_sns_topic.slack_sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_slack_lmf.arn
}
