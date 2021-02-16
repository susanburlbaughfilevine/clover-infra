import json
import logging
import os

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

'''Octopus Deploy Variables'''
SLACK_CHANNEL = os.environ['SLACK_CHANNEL']
HOOK_URL = os.environ['HOOK_URL']

# HOOK_URL = "https://hooks.slack.com/services/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"

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):

    skipMessages = [
        "ElastiCache:SnapshotComplete",
        "Finished DB Instance backup",
        "Backing up DB instance",
        "Automated snapshot created",
        "Creating automated snapshot",
        "ElastiCache:CacheClusterProvisioningComplete",
        "ElastiCache:CreateReplicationGroupComplete",
        "ElastiCache:DeleteCacheClusterComplete",
        "Elasticache:ServiceUpdateAvailableForNode"
    ]

    logger.info("Starting function...")
    logger.info("Event: " + str(event))

    records = (event['Records'][0])
    message = json.loads(event['Records'][0]['Sns']['Message'])

    logger.info("Message: " + str(message))

    alarm_name = message.get('AlarmName')

    if alarm_name is None:
        slack_message = {
            'channel': SLACK_CHANNEL,
            'text': f"{message}"
        }

        new_state = message.get('Event Message')

    else:
        account_id = message['AWSAccountId']
        region = records['EventSubscriptionArn'].split(":")[3]   # Grabs the region in the correct format since the message uses the wrong version for links
        new_state = message['NewStateValue']            # Current alarm state
        reason = message['NewStateReason']              # reason for alarm
        color = 'good'                                  # default alarm color
        # alarm_link = f"<https://console.aws.amazon.com/cloudwatch/home?region={region}#alarm:alarmFilter=ANY;name={alarm_name}|Link to Alarm>"
        alarm_link = f"https://console.aws.amazon.com/cloudwatch/home?region={region}#alarm:alarmFilter=ANY;name={alarm_name}"
        slack_message = {}
    
        '''Change alarm colors based on severity or if clear'''
        if new_state == 'ALARM':
            color = 'danger'
            icon = ':yelling_at_cloud:'
            slack_message = {
                'channel': SLACK_CHANNEL,
                'attachments': [
                    {
                        'color': color,
                        'text': f"*{alarm_name}* state is now *{new_state}* {icon}\n"
                                f"\n*Account/Region*:\n{account_id}\n{region}\n"
                                f"\n*Reason*:\n{reason}\n"
                    },
                    {
                        'color': color,
                        'text': "Link to Alarm",
                        'actions': [
                            {
                                'name': 'alarm',
                                'text': 'View',
                                'type': 'button',
                                'value': 'alarmlink',
                                'url': alarm_link
                            }
    
                        ]
                    }
                ]
            }
    
        elif new_state == 'OK':
            color = 'good'
            icon = ':success:'
            slack_message = {
                'channel': SLACK_CHANNEL,
                'attachments': [
                    {
                        'color': color,
                        'text': f"*{alarm_name}* state is now *{new_state}* {icon}\n"
                                f"\n*Account/Region*:\n{account_id}\n{region}\n"
                                f"\n*Reason*:\n{reason}\n"
                    },
                    {
                        'color': color,
                        'text': "Link to Alarm",
                        'actions': [
                            {
                                'name': 'alarm',
                                'text': 'View',
                                'type': 'button',
                                'value': 'alarmlink',
                                'url': alarm_link
                            }
    
                        ]
                    }
                ]
            }

    req = Request(HOOK_URL, json.dumps(slack_message).encode('utf-8'))

    '''Check for alarms that aren't critical (auto-scaling actions, etc.)'''
    if any(message_state in new_state for message_state in skipMessages):
        logger.info('Skip message evaluate non-important alarm. Logging. Will not send to Slack.')
        logger.info(f'Alarm state to log: {new_state}')
    else:
        try:
            response = urlopen(req)
            response.read()
            logger.info("Message posted to %s", slack_message['channel'])
        except HTTPError as e:
            logger.error("Request failed: %d %s", e.code, e.reason)
        except URLError as e:
            logger.error("Server connection failed: %s", e.reason)
