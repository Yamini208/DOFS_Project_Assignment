import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['FAILED_TABLE']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    print("✅ DLQ Lambda triggered")
    print(f"📦 Raw event: {json.dumps(event)}")

    for record in event.get('Records', []):
        try:
            body = json.loads(record['body'])
            print(f"📄 Record body: {body}")
            response = table.put_item(Item=body)
            print(f"📝 Writing to DynamoDB: {response}")
        except Exception as e:
            print(f"❌ Error inserting to DynamoDB: {e}")

    return {
        'statusCode': 200,
        'body': json.dumps('DLQ message stored')
    }