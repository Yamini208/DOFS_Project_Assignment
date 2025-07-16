def lambda_handler(event, context):
    if 'order_id' not in event or 'item' not in event or 'quantity' not in event:
        raise Exception("Invalid order format")
    return event
