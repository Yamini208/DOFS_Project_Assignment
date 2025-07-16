import json
import boto3
import os

sfn = boto3.client('stepfunctions')
STATE_MACHINE_ARN = os.environ['SFN_ARN']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])

        sfn.start_execution(
            stateMachineArn=STATE_MACHINE_ARN,
            input=json.dumps(body)
        )

        return {
            'statusCode': 202,
            'body': json.dumps({'message': 'Order accepted'})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
