def lambda_handler(event, context):
    if 'order_id' not in event or 'items' not in event:
        raise Exception("Invalid order format")
    return event