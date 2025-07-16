import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['ORDER_TABLE'])

def lambda_handler(event, context):
    event['order_status'] = 'PENDING'
    table.put_item(Item=event)
    return event
