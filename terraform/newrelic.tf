
resource "newrelic_alert_channel" "warnings" {
  name = "${var.envName}-alert-channel"
  type = "slack"

  config {
    url     = var.nr_slack_webhook
    channel = var.nr_slack_channel
  }
}

/* resource "newrelic_alert_policy" "ServiceStatus" {
  name = "${var.envName}-clover-service-status"
  channel_ids = [
    newrelic_alert_channel.warnings.id
  ]
} */

