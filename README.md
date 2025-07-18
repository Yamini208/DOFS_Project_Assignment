**Project Assignment: Distributed Order Fulfillment System (DOFS) with CI/CD Objective**

**1. Project Overview:**
                The Distributed Order Fulfillment System (DOFS) is designed to handle order processing asynchronously, ensuring high availability, scalability, and resilience using serverless technologies. Orders are ingested via an API, validated, stored, and then processed through a fulfillment workflow. Unsuccessful fulfillment attempts are gracefully handled via a Dead-Letter Queue (DLQ). Infrastructure provisioning and application deployment are fully automated using Terraform and managed through an AWS CodePipeline-driven CI/CD pipeline, targeting a DEV environment.
   
**2. Architecture Overview:**
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

**3. Functional Components:**

* API Handler (Lambda): A RESTful endpoint exposed via API Gateway that accepts POST /order requests. It initiates the Step Function execution for order processing.

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

**4. Prerequisites:**

Before you begin, ensure you have the following installed and configured:

* AWS Account: An active AWS account with sufficient permissions to create IAM roles, EC2 instances (for CodeBuild environment), S3 buckets, API Gateway, Lambda functions, Step Functions, DynamoDB, and SQS.

* AWS CLI: Configured with credentials for your AWS account and default region (us-east-1 recommended for consistency).

* Install: ```curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install``` (for Linux) or refer to AWS CLI Installation Guide.

* Configure: aws configure

* Terraform: Version 1.0.0 or higher.

* Install: Follow the instructions on the Terraform website.

* Git: For cloning the repository and version control.

* Install: ```sudo apt-get install git``` (Debian/Ubuntu) or refer to Git Installation Guide.

* GitHub Repository: Your project code should be hosted in a GitHub repository.

* Node.js / npm (Optional, for API testing): If you plan to use tools like curl or Postman, these are not strictly necessary but might be useful for local testing or custom scripts.

**5. Setup Instructions:**

Follow these steps to set up and deploy the DOFS project.

**1. AWS Setup:** This section covers the initial manual setup required before your CI/CD pipeline can take over.

1. Create an S3 Bucket for Terraform State:

This bucket will store your Terraform state files, enabling remote state management and state locking.

* Go to the S3 console in your chosen region (us-east-1 recommended).

* Click "Create bucket".

* Give it a unique name (e.g., dofs-terraform-state-YOUR_ACCOUNT_ID).

* Keep default settings, but consider enabling Versioning and Server-Side Encryption for best practices.

* Create the bucket.

2. Create AWS CodeConnections to GitHub:

This connection allows AWS services (CodePipeline, CodeBuild) to securely access your GitHub repository.

* Go to the AWS CodeConnections console (https://console.aws.amazon.com/codesuite/settings/connections) in us-east-1.

* Click "Create connection".

* Select "GitHub" as the provider.

* Provide a descriptive name (e.g., dofs-github-connection).

* Click "Connect to GitHub". This will redirect you to GitHub to authorize the AWS Connector for GitHub app.

* Follow the GitHub prompts, ensuring you grant access to the repository containing this project.

* Once authorized, you'll be redirected back to the AWS console. Finish creating the connection.

* Note down the Connection ARN (e.g., arn:aws:codeconnections:us-east-1:YOUR_ACCOUNT_ID:connection/YOUR_CONNECTION_ID). You will need this for the CI/CD Terraform.

**2.  Local Setup:**
1. Clone the Repository:
   ```
   git clone YOUR_GITHUB_REPO_URL
   cd dofs-project
2. Prepare Lambda Dependencies:

Navigate into each lambda directory and install its dependencies. Ensure requirements.txt is present in each as per the folder structure.
```
cd lambdas/api_handler
pip install -r requirements.txt -t . # Use -t . to install into the current directory for zipping
cd ../validator
pip install -r requirements.txt -t .
cd ../order_storage
pip install -r requirements.txt -t .
cd ../fulfill_order
pip install -r requirements.txt -t .
cd ../.. # Go back to the dofs-project root
```

3. GitHub Configuration:
   
Ensure your ```main``` branch (or ```master```) is protected and that pull requests are used for merging changes. This project assumes your buildspec.yml is at the root of your repository.

4. Initial CI/CD Deployment:

This step provisions your CodePipeline and CodeBuild project using Terraform.

* Update Terraform Backend Configuration:

Edit ```terraform/cicd/backend.tf``` and ```terraform/backend.tf``` to point to the S3 bucket you created earlier.
```
# terraform/cicd/backend.tf (and terraform/backend.tf)
terraform {
  backend "s3" {
    bucket = "dofs-terraform-state-YOUR_ACCOUNT_ID" # REPLACE with your S3 bucket name
    key    = "cicd/terraform.tfstate"                 # For cicd backend.tf
    # key    = "dofs-dev/terraform.tfstate"             # For main terraform backend.tf
    region = "us-east-1"
    encrypt = true
  }
}
```
* Update CI/CD Terraform Variables:

Edit ```terraform/cicd/main.tf``` (or ```variables.tf``` if defined there) to pass your CodeConnections ARN and repository details.
```
# Example snippet within terraform/cicd/main.tf (look for codepipeline resource)
resource "aws_codepipeline" "dofs_pipeline" {
  # ... other settings
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        ConnectionArn    = "arn:aws:codeconnections:us-east-1:YOUR_ACCOUNT_ID:connection/YOUR_CONNECTION_ID" # REPLACE
        FullRepositoryId = "YOUR_GITHUB_USERNAME/dofs-project" # REPLACE
        BranchName       = "main" # Or your primary branch
      }
    }
  }
  # ...
}
```
* Deploy CI/CD Infrastructure:

From the ```dofs-project``` root directory:
```
cd terraform/cicd
terraform init -backend-config="bucket=dofs-terraform-state-YOUR_ACCOUNT_ID" -backend-config="key=cicd/terraform.tfstate" -backend-config="region=us-east-1"
terraform plan -out=cicd.tfplan
terraform apply cicd.tfplan
```
This will create your CodePipeline, CodeBuild project, and associated IAM roles.

5.  Application Deployment (via CI/CD):

Once the CI/CD pipeline is deployed, it should automatically trigger. Any git push to your configured branch (e.g., ```main```) will initiate a new pipeline execution.
* Initial Push: Make a small change to your ```README.md``` or a dummy file and push it to trigger the pipeline if it doesn't automatically start after creation.
```
echo "Initial commit to trigger pipeline" >> README.md
git add README.md
git commit -m "Trigger initial pipeline build"
git push origin main
```
* Monitor the Pipeline: Go to the AWS CodePipeline console and monitor the execution. It will go through Source, Build, and potentially an Approval stage before deploying the application infrastructure to ```DEV```.

**6. Troubleshooting:**
This section provides common issues and solutions.

**+ Connection not found" in CodePipeline/CodeBuild Source:**
1. Issue: The CodePipeline or CodeBuild project is configured with a CodeConnections ARN that doesn't exist or is inaccessible.

2. Solution: Go to AWS CodeConnections console (us-east-1 recommended region), verify the connection exists, note its exact ARN. Then, edit your CodePipeline's Source stage and update the "Connection ARN" field to match the correct ARN. If the connection was accidentally deleted, recreate it and update the pipeline.

+ ```ERROR: Could not open requirements file: [Errno 2] No such file or directory: 'requirements.txt'``` **in CodeBuild:**
1. Issue: The ```pip install -r requirements.txt``` command cannot find the ```requirements.txt file``` at the expected location.

2. Solution: Ensure your ```buildspec.yml``` correctly navigates to the directory containing the ```requirements.txt``` before attempting to install. For multiple ```requirements.txt``` files, use the find and loop approach as described in the ```buildspec.yml``` template.

**+ Terraform errors during ```terraform apply```:**
1. Issue: IAM permissions, resource limits, syntax errors in .tf files, or conflicts with existing AWS resources.

2. Solution: Carefully read the Terraform error message; it usually points to the exact problem.

* IAM: Ensure the IAM role used by CodeBuild for Terraform operations has permissions for all AWS resources it's trying to create/modify (e.g., lambda:*, apigateway:*, dynamodb:*, sqs:*, states:*).

* Syntax: Run terraform validate locally to catch syntax errors.

* Resource Limits: Check AWS Service Quotas if you suspect hitting limits.

* State Locking: Ensure your S3 backend configuration includes dynamodb_table for state locking to prevent concurrent apply issues.

**+ Lambda function not found / CodeDeploy errors:**
1. Issue: Often means the Lambda deployment package wasn't correctly created or uploaded by Terraform, or the Lambda resource in Terraform is misconfigured.

2. Solution: Check CodeBuild logs for errors during the terraform apply phase. Ensure the Lambda zip files are correctly packaged and referenced in your Terraform aws_lambda_function resources.

**7. Pipeline Explanation:**

The CI/CD pipeline is defined using Terraform and orchestrated by AWS CodePipeline.

* **Source Stage:**

* Provider: GitHub (via AWS CodeConnections).

* Trigger: Automatically starts a new pipeline execution on every git push to the main branch.

* Action: Fetches the latest code from the GitHub repository and places it into an S3 artifact bucket.

* **Build Stage (AWS CodeBuild):**

* Environment: A managed CodeBuild environment (e.g., aws/codebuild/standard:6.0 or custom).

* buildspec.yml: This file (located at the root of the repository) defines the build commands:

* install phase:

1. Installs Python dependencies for each Lambda function by iterating through their respective directories (lambdas/<function_name>/requirements.txt).

2. Ensures pip is updated.

3. (Potentially installs Terraform if not pre-installed in the CodeBuild image.)

* build phase:

1. Navigates to terraform/cicd to initialize and apply Terraform for the CI/CD resources (CodePipeline, CodeBuild project itself). This ensures the pipeline's infrastructure can be updated by the pipeline.

2. Navigates to terraform/ (the root of the application's Terraform modules) to initialize and apply Terraform, deploying all DOFS application infrastructure (API Gateway, Lambdas, Step Functions, DynamoDB, SQS) to the DEV environment.

* **Artifacts:**

The build output (though not explicitly used by CodePipeline's subsequent stages in this Terraform-centric deployment) is stored.

* **Deployment Model:**

* This pipeline uses a GitOps/Infrastructure-as-Code (IaC) driven deployment model. Terraform apply commands are executed directly within the CodeBuild stage.

* Any change to the .tf files in the terraform/ directory (or lambdas/ code which is packaged by Terraform) will trigger the pipeline, and Terraform will calculate and apply the necessary infrastructure updates.

* This setup ensures that your infrastructure is always defined by your version-controlled Terraform code.
