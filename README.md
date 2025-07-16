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
DynamoDB update + DLQ```
