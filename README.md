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

-- orders: Stores all order details with order_id as the primary key.

-- failed_orders: Stores messages from the DLQ for auditing and further analysis.

* SQS Queues:

-- order_queue: Standard SQS queue for order fulfillment messages.

-- order_dlq: Dead-Letter Queue for messages that fail processing by the Fulfillment Lambda.

* DLQ & Alerting: Unsuccessful messages (after maxReceiveCount retries) from order_queue are routed to order_dlq. A mechanism (e.g., Lambda trigger) reads from order_dlq and writes these failed messages to the failed_orders DynamoDB table.

4. Prerequisites
Before you begin, ensure you have the following installed and configured:

* AWS Account: An active AWS account with sufficient permissions to create IAM roles, EC2 instances (for CodeBuild environment), S3 buckets, API Gateway, Lambda functions, Step Functions, DynamoDB, and SQS.

* AWS CLI: Configured with credentials for your AWS account and default region (us-east-1 recommended for consistency).

* Install: ```curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install``` (for Linux) or refer to AWS CLI Installation Guide.

Configure: aws configure

Terraform: Version 1.0.0 or higher.

Install: Follow the instructions on the Terraform website.

Git: For cloning the repository and version control.

Install: sudo apt-get install git (Debian/Ubuntu) or refer to Git Installation Guide.

GitHub Repository: Your project code should be hosted in a GitHub repository.

Node.js / npm (Optional, for API testing): If you plan to use tools like curl or Postman, these are not strictly necessary but might be useful for local testing or custom scripts.
