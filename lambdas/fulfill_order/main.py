import json
import os
import random
import boto3

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['ORDER_TABLE']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    print("✅ Fulfill Order Lambda triggered")
    print(f"📦 Raw event: {json.dumps(event)}")

    # Handle both SQS events and direct Step Function invocations
    if "Records" in event:
        # Event came from SQS trigger
        records = event["Records"]
    else:
        # Event came directly from Step Function
        # Wrap in Records-like structure for consistent processing
        records = [{"body": json.dumps(event)}]

    for record in records:
        try:
            order = json.loads(record['body'])
            print(f"🛒 Order received: {order}")

            # Debugging: Check for force_fail
            if "force_fail" in order:
                print(f"✅ force_fail detected: {order['force_fail']}")
            else:
                print("❌ force_fail not found in order payload")

            # Simulate 70% success rate OR force failure manually
            if order.get("force_fail") or random.random() >= 0.7:
                print("❌ Simulated failure")
                raise Exception("Simulated processing failure")
            else:
                print("✅ Fulfillment succeeded")

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
