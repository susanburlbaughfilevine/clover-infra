/* 
resource "newrelic_alert_channel" "warnings" {
  name = "${var.envName}-alert-channel"
  type = "slack"

  config {
    url     = var.nr_slack_webhook
    channel = var.nr_slack_channel
  }
} 
*/
