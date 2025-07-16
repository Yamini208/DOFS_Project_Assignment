import json
import os
import random
import boto3

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')

# Get environment variables for tables
order_table_name = os.environ['ORDER_TABLE']
failed_order_table_name = os.environ['FAILED_ORDER_TABLE']

order_table = dynamodb.Table(order_table_name)
failed_order_table = dynamodb.Table(failed_order_table_name)

def lambda_handler(event, context):
    print("✅ Fulfill Order Lambda triggered")
    print(f"📦 Raw event: {json.dumps(event)}")

    try:
        # If Step Functions sends payload directly
        order = event

        print(f"🛒 Order received: {order}")

        # Simulate fulfillment failure
        if order.get("force_fail") or random.random() >= 0.7:
            print("❌ Simulated failure")
            # Set the order_status to FAILED
            order["order_status"] = "FAILED"
            # Write the failed order to failed_orders table
            failed_order_table.put_item(Item=order)
            print(f"⚠️ Order written to {failed_order_table_name}")
            raise Exception("Simulated processing failure")

        # If success, update status and write to orders table
        order["order_status"] = "FULFILLED"
        response = order_table.put_item(Item=order)
        print(f"✅ Order fulfilled and written to {order_table_name}: {response}")

    except Exception as e:
        print(f"❗ Error processing order: {str(e)}")
        raise e  # Let Step Functions catch the error and apply retries or catch

    return {
        "statusCode": 200,
        "body": json.dumps("Fulfillment Lambda executed")
    }
