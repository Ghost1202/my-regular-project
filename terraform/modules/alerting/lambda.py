import json
import urllib.request
import boto3
import os

def handler(event, context):
    secret_arn = os.environ['DISCORD_WEBHOOK_SECRET_ARN']
    client = boto3.client('secretsmanager')
    secret = client.get_secret_value(SecretId=secret_arn)
    webhook_url = json.loads(secret['SecretString'])['webhook_url']

    sns_message = event['Records'][0]['Sns']['Message']

    try:
        alarm = json.loads(sns_message)
        alarm_name = alarm.get('AlarmName', 'Unknown')
        new_state = alarm.get('NewStateValue', 'Unknown')
        reason = alarm.get('NewStateReason', 'Unknown')

        if new_state == 'ALARM':
            color = 16711680
            emoji = '🔴'
        elif new_state == 'OK':
            color = 65280
            emoji = '🟢'
        else:
            color = 16776960
            emoji = '🟡'

        message = {
            "embeds": [{
                "title": f"{emoji} {alarm_name}",
                "description": reason,
                "color": color
            }]
        }
    except Exception:
        message = {"content": f"Alert: {sns_message}"}

    data = json.dumps(message).encode('utf-8')
    req = urllib.request.Request(
        webhook_url,
        data=data,
        headers={'Content-Type': 'application/json'}
    )
    urllib.request.urlopen(req)