# Log Management API - DevOps Project

A DevOps project that implements a simple log collection API using **Node.js and PostgreSQL**, containerized with **Docker Compose** and provisioned on **AWS using Terraform**.

The project focuses on containerization, Infrastructure as Code, secrets management, remote Terraform state, Linux automation, and Continuous Integration.

## Architecture

```text
                       GitHub
                          |
                    GitHub Actions
                          |
                +---------+---------+
                |                   |
             Node.js             Terraform
             Docker          fmt + validate
                |
                |
                v
                   AWS Infrastructure
                          |
                         VPC
                          |
                    Public Subnet
                          |
                  Internet Gateway
                          |
                     Route Table
                          |
                   Security Group
                          |
                         EC2
                          |
                      user_data
                          |
                 Docker Compose
                    /        \
                   /          \
              Node.js      PostgreSQL
                 |
                 |
          AWS Secrets Manager


Terraform Remote State
        |
        v
       S3
```

## Technologies

- Node.js
- PostgreSQL
- Docker
- Docker Compose
- Bash
- Terraform
- AWS
  - EC2
  - VPC
  - S3
  - IAM
  - Secrets Manager
- GitHub Actions
- Linux

## Application

The application exposes a simple REST API used to collect and retrieve logs.

### Endpoints

```text
GET  /
GET  /logs
POST /logs
```

A log can be sent using:

```bash
curl -X POST http://localhost:3000/logs \
  -H "Content-Type: application/json" \
  -d '{"level":"ERROR","message":"Database timeout"}'
```

Logs can then be retrieved using:

```bash
curl http://localhost:3000/logs
```

## Log Collection

A Bash script reads application logs from:

```text
logs/app.log
```

Example:

```text
INFO Server started successfully
INFO User login
WARNING Disk usage is high
ERROR Database timeout
```

The script separates each entry into a log level and message:

```text
ERROR Database timeout
  |          |
  |          +---- message
  |
  +--------------- level
```

It then sends each entry to the Node.js API:

```text
logs/app.log
      |
      v
 Bash script
      |
      | HTTP POST /logs
      v
 Node.js API
      |
      v
 PostgreSQL
```

This simulates a simple log ingestion pipeline.

## Docker

The application is composed of two containers.

```text
Docker Compose
|
+-- app-node
|     |
|     +-- Node.js REST API
|     +-- Port 3000
|
+-- postgresql_service
      |
      +-- PostgreSQL database
      +-- Persistent Docker volume
```

The PostgreSQL container includes a health check.

The Node.js application starts after PostgreSQL becomes healthy.

Start the environment with:

```bash
docker compose up -d
```

Check the containers:

```bash
docker compose ps
```

Stop the environment:

```bash
docker compose down
```

## Database

PostgreSQL is initialized using:

```text
init-db.sql
```

Database data is persisted using a Docker volume so that data survives container recreation.

## AWS Infrastructure

The AWS infrastructure is defined using Terraform.

Terraform manages:

- VPC
- Subnet
- Internet Gateway
- Route Table
- Route Table Association
- Security Group
- EC2 instance
- IAM Role
- IAM Policy
- IAM Instance Profile
- AWS Secrets Manager secrets
- S3 Terraform backend

The EC2 instance is configured automatically using `user_data`.

## EC2 Bootstrap

When the EC2 instance starts, the Terraform `user_data` script:

1. Updates system packages
2. Installs Docker
3. Installs Docker Compose
4. Installs Git
5. Installs AWS CLI
6. Starts Docker
7. Clones the project repository
8. Retrieves database credentials from AWS Secrets Manager
9. Creates the required Docker secret files
10. Starts the application with Docker Compose

This allows a newly provisioned instance to configure the application automatically.

## Secrets Management

Database credentials are **not stored in the Git repository**.

AWS Secrets Manager stores:

```text
log-app/db-user
log-app/db-password
log-app/db-name
```

The EC2 instance accesses these secrets using an IAM Role.

The IAM policy grants:

```text
secretsmanager:GetSecretValue
```

only for the required application secrets.

No AWS access keys are stored on the EC2 instance for this purpose.

## Terraform Remote State

Terraform state is stored remotely using an **Amazon S3 backend**.

```text
Terraform
    |
    v
Amazon S3
    |
    +-- terraform.tfstate
```

Local state files are excluded from Git.

The backend also uses Terraform state locking to protect against concurrent state modifications.

## Terraform

Terraform configuration is located in:

```text
terraform/
```

Before committing Terraform changes:

```bash
cd terraform

terraform fmt
terraform validate
```

Infrastructure changes can be inspected using:

```bash
terraform plan
```

## Continuous Integration

The project uses **GitHub Actions** for Continuous Integration.

Two areas are validated.

### Application

```text
Checkout
   |
Setup Node.js
   |
npm ci
   |
Docker Build
```

### Terraform

```text
Checkout
   |
Setup Terraform
   |
terraform fmt -check
   |
terraform init -backend=false
   |
terraform validate
```

The CI workflow intentionally initializes Terraform with:

```bash
terraform init -backend=false
```

because CI only validates the Terraform configuration and does not require access to the remote S3 state.

Infrastructure deployment is not performed automatically by the CI pipeline.

## Running Locally

Clone the repository:

```bash
git clone https://github.com/AlexCosmeen/proiect_logs_devops.git
cd proiect_logs_devops
```

Create the required local secret files:

```text
secrets/
├── db_user.txt
├── db_password.txt
└── db_name.txt
```

Then start the containers:

```bash
docker compose up -d
```

Verify the API:

```bash
curl http://localhost:3000/
```

Send a test log:

```bash
curl -X POST http://localhost:3000/logs \
  -H "Content-Type: application/json" \
  -d '{"level":"INFO","message":"Application test"}'
```

Retrieve stored logs:

```bash
curl http://localhost:3000/logs
```

Run the Bash log ingestion script:

```bash
./scripts/read.sh
```

Then retrieve the logs again:

```bash
curl http://localhost:3000/logs
```

## Project Structure

```text
.
├── .github/
│   └── workflows/
│
├── app/
│   ├── Dockerfile
│   ├── index.js
│   ├── package.json
│   └── package-lock.json
│
├── logs/
│   └── app.log
│
├── scripts/
│   └── read.sh
│
├── terraform/
│   ├── iam.tf
│   ├── main.tf
│   ├── network.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── .terraform.lock.hcl
│
├── docker-compose.yml
├── init-db.sql
├── .gitignore
└── README.md
```

Files containing local or sensitive data are excluded using `.gitignore`.

## Security

The project follows several basic security practices:

- Database credentials are excluded from Git
- Database credentials are stored in AWS Secrets Manager
- EC2 uses an IAM Role instead of static AWS credentials
- IAM access to Secrets Manager follows least privilege
- SSH access is restricted to a configurable CIDR
- Terraform state files are excluded from Git
- Terraform state is stored remotely in S3
- `.terraform/` is excluded from Git
- `node_modules/` is excluded from Git
- Local secret files are excluded from Git

## Future Improvements

Possible future improvements include:

- Automated API tests
- Docker image vulnerability scanning
- Amazon ECR for Docker images
- GitHub Actions authentication to AWS using OIDC
- Terraform Plan validation in pull requests
- Automated deployment
- HTTPS
- Monitoring and alerting
- Amazon RDS instead of running PostgreSQL inside EC2

## Purpose

This project was built as a hands-on DevOps project to practice:

- Linux and Bash scripting
- REST APIs
- PostgreSQL
- Docker and Docker Compose
- Infrastructure as Code with Terraform
- AWS networking
- IAM
- Secrets management
- Remote Terraform state
- EC2 bootstrap automation
- Continuous Integration with GitHub Actions
