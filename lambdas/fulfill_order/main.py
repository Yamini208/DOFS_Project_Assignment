import json
import os
import random
import boto3

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['ORDER_TABLE']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    print("✅ Fulfill Order Lambda triggered")
    print(f"📦 Raw event: {json.dumps(event)}")

    for record in event.get('Records', []):
        try:
            order = json.loads(record['body'])
            print(f"🛒 Order received: {order}")

            # Simulate 70% success rate or force failure manually
            if order.get("force_fail") or random.random() >= 0.7:
                print("❌ Simulated failure")
                raise Exception("Simulated processing failure")

            # Fulfillment successful, update status
            order["status"] = "FULFILLED"
            response = table.put_item(Item=order)
            print(f"✅ Order fulfilled and written to DynamoDB: {response}")

        except Exception as e:
            print(f"❗ Error processing order: {str(e)}")
            raise e  # Allow Lambda retry & DLQ redirection

    return {
        "statusCode": 200,
        "body": json.dumps("Fulfillment Lambda executed")
    }
