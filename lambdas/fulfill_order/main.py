import json
import os
import random
import boto3

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')

# Get table names from environment variables
orders_table_name = os.environ['ORDER_TABLE']           # orders table
failed_table_name = os.environ['FAILED_ORDER_TABLE']    # failed_orders table

orders_table = dynamodb.Table(orders_table_name)
failed_table = dynamodb.Table(failed_table_name)

def lambda_handler(event, context):
    print("✅ Fulfill Order Lambda triggered")
    print(f"📦 Raw event: {json.dumps(event)}")

    for record in event.get('Records', []):
        try:
            order = json.loads(record['body'])
            print(f"🛒 Order received: {order}")

            # Simulate 70% success rate or force failure manually
            if order.get("force_fail") or random.random() >= 0.7:
                print("❌ Simulated failure, writing to failed_orders table")
                
                # Write failed order to failed_orders table
                failed_table.put_item(Item=order)
                raise Exception("Simulated processing failure")

            # Fulfillment successful, update status
            order["status"] = "FULFILLED"
            response = orders_table.put_item(Item=order)
            print(f"✅ Order fulfilled and written to orders table: {response}")

        except Exception as e:
            print(f"❗ Error processing order: {str(e)}")
            raise e  # Allow Lambda retry & DLQ redirection

    return {
        "statusCode": 200,
        "body": json.dumps("Fulfillment Lambda executed")
    }
