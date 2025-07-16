import boto3
import os
import json

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    print(f"📦 Received event: {json.dumps(event)}")

    # Determine which table to use based on order_status
    if event.get('order_status') == 'FAILED':
        table_name = os.environ['FAILED_ORDER_TABLE']
    else:
        table_name = os.environ['ORDER_TABLE']

    table = dynamodb.Table(table_name)

    # Write the order to the appropriate table
    table.put_item(Item=event)
    print(f"✅ Order written to {table_name}")

    return event
