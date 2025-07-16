Project Assignment: Distributed Order Fulfillment System (DOFS) with CI/CD Objective

1. Project Overview:
                The Distributed Order Fulfillment System (DOFS) is designed to handle order processing asynchronously, ensuring high availability, scalability, and resilience using serverless technologies. Orders are ingested via an API, validated, stored, and then processed through a fulfillment workflow. Unsuccessful fulfillment attempts are gracefully handled via a Dead-Letter Queue (DLQ). Infrastructure provisioning and application deployment are fully automated using Terraform and managed through an AWS CodePipeline-driven CI/CD pipeline, targeting a DEV environment.
   
2. Architecture Overview:
```
API Gateway --> Lambda (API Handler)
  |
  v
Step Function Orchestrator
  |
  +-------------------+------------------------+
  |                   |                        |
  v                   v                        v
Validate Lambda --> DynamoDB (orders) --> SQS --> Fulfillment Lambda
  |
  v
DynamoDB update + DLQ
```

3. Functional Components
API Handler (Lambda): A RESTful endpoint exposed via API Gateway that accepts POST /order requests. It initiates the Step Function execution for order processing.

* Step Function (Orchestrator): A serverless workflow that orchestrates the order processing. It includes:

* Validate Order Lambda: Performs initial validation of the order payload.

* Store Order Lambda: Persists valid order details into the orders DynamoDB table.

* Push to SQS: Enqueues the order message into order_queue for asynchronous fulfillment.

* Fulfillment Lambda: Triggered by messages from the order_queue SQS queue. It simulates order processing with a 70% success rate. Upon completion (success or failure), it updates the order status in the orders DynamoDB table. Messages that fail processing after configured retries are moved to a Dead-Letter Queue.

* DynamoDB Tables:

- orders: Stores all order details with order_id as the primary key.

- failed_orders: Stores messages from the DLQ for auditing and further analysis.

* SQS Queues:

- order_queue: Standard SQS queue for order fulfillment messages.

- order_dlq: Dead-Letter Queue for messages that fail processing by the Fulfillment Lambda.

* DLQ & Alerting: Unsuccessful messages (after maxReceiveCount retries) from order_queue are routed to order_dlq. A mechanism (e.g., Lambda trigger) reads from order_dlq and writes these failed messages to the failed_orders DynamoDB table.
