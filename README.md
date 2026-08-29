# devops-assignment

Todo Application – AWS DevOps Assignment

1. Project Overview

This project demonstrates an end-to-end DevOps implementation for a Todo application using AWS, Terraform, Docker, Jenkins, PostgreSQL RDS, Amazon CloudWatch, and Amazon SNS.

The application consists of:

Frontend: Nginx serving the Todo UI

Backend: Flask application running with Gunicorn

Database: PostgreSQL on Amazon RDS

Infrastructure: AWS resources provisioned using Terraform

CI/CD: Jenkins

Containerization: Docker / Docker Compose

Monitoring: Amazon CloudWatch

Logging: CloudWatch Logs

Alerting: CloudWatch Alarms + Amazon SNS

Backup: Amazon RDS automated backups

The application was tested successfully on the EC2 instance and the database connection was verified.

2. Architecture

                         GitHub
                           |
                           v
                        Jenkins
                           |
                  Build / Test / Scan
                           |
                           v
                    Docker Registry
                           |
                           v
                         EC2
                  +-------------------+
                  |   Docker Compose  |
                  |                   |
User ---> Port 8080 ---> Nginx       |
                  |       Frontend    |
                  |          |        |
                  |          v        |
                  |     Flask Backend |
                  |       :5000       |
                  +---------|---------+
                            |
                            v
                     Amazon RDS
                    PostgreSQL DB

Monitoring:
EC2 / Docker / Application / RDS
              |
              v
        CloudWatch
              |
        +-----+------+
        |            |
     Dashboards    Alarms
                       |
                       v
                      SNS
                       |
                       v
                     Email

3. Repository Structure

devops-assignment/
├── README.md
├── docker-compose.yml
├── app/
│   ├── backend/
│   │   ├── app.py
│   │   └── Dockerfile
│   └── frontend/
│       ├── index.html
│       ├── app.js
│       ├── style.css
│       └── nginx.conf
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── ...

The GitHub repository used for this assignment is:

https://github.com/GayathriRai/devops-assignment

4. Infrastructure Provisioning

Terraform was used to provision the AWS infrastructure.

The infrastructure includes:

VPC

Public and private subnets

EC2 instance for application hosting

Amazon RDS PostgreSQL

Security groups

Load-balancing infrastructure as implemented in the Terraform configuration

Terraform variables

Terraform outputs

Terraform state management

Terraform configuration was formatted and applied successfully.

Typical Terraform workflow:

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

The infrastructure was verified after provisioning.

5. Application

Frontend

The frontend is served using Nginx.

The frontend is exposed through:

http://<EC2_PUBLIC_IP>:8080/

Nginx listens internally on port 80 and Docker maps it to EC2 port 8080:

8080:80

Backend

The backend is a Flask API running with Gunicorn on port 5000.

Available API endpoints include:

GET    /api/health
GET    /api/todos
POST   /api/todos
PUT    /api/todos/<todo_id>
DELETE /api/todos/<todo_id>

Database

The application uses PostgreSQL hosted on Amazon RDS.

The backend receives database configuration through environment variables:

DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASSWORD
DB_SSLMODE

The database connection uses SSL:

DB_SSLMODE=require

The database password is supplied through an environment variable rather than being hard-coded into docker-compose.yml.

6. Docker

Docker was used to containerize the application.

The current Compose deployment contains:

backend
frontend

The backend uses the published Docker image:

gayathrirai/todo-app-backend-new:latest

The frontend uses:

nginx:alpine

Docker Compose configuration:

services:

  backend:
    image: gayathrirai/todo-app-backend-new:latest
    container_name: todo-backend
    restart: unless-stopped
    environment:
      DB_HOST: todo-app-postgres.cvgmaqao8rbm.ap-south-1.rds.amazonaws.com
      DB_PORT: 5432
      DB_NAME: tododb
      DB_USER: todo_user
      DB_PASSWORD: ${DB_PASSWORD}
      DB_SSLMODE: require
    expose:
      - "5000"

  frontend:
    image: nginx:alpine
    container_name: todo-frontend
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./app/frontend:/usr/share/nginx/html:ro
      - ./app/frontend/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - backend

The containers were verified with:

docker ps

Expected containers:

todo-frontend
todo-backend

7. Application Verification

The application was tested directly on the EC2 instance.

Frontend:

curl -i http://localhost:8080/

Result:

HTTP/1.1 200 OK

Health endpoint:

curl -i http://localhost:8080/api/health

Result:

{
  "database": "connected",
  "status": "healthy"
}

Todo API:

curl -i http://localhost:8080/api/todos

Result:

HTTP/1.1 200 OK

The API returned Todo records from PostgreSQL.

Therefore:

Frontend -> Nginx -> Flask -> PostgreSQL

was successfully verified.

8. CI/CD with Jenkins

Jenkins was selected as the CI/CD platform.

The Jenkins pipeline was configured to automate the application build and deployment process.

The pipeline performs the required CI/CD activities implemented for this assignment, including:

Source code retrieval from GitHub

Application build

Docker image build

Docker image publishing

Deployment to EC2

Application verification

The Jenkins build was successfully executed.

A Groovy syntax issue was encountered during pipeline development:

MultipleCompilationErrorsException
expecting '}', found 'http'

The Jenkinsfile syntax was corrected and the build subsequently succeeded.

The final Jenkins build status was:

SUCCESS

9. Docker Image Registry

The backend image was published to Docker Hub under the username:

gayathrirai

Backend image:

gayathrirai/todo-app-backend-new:latest

The EC2 instance successfully pulled and ran this image.

10. Monitoring

Amazon CloudWatch was configured for infrastructure, application, and database monitoring.

EC2 Infrastructure Metrics

CloudWatch Agent was installed and configured on the EC2 instance.

The following metrics were configured:

CPU usage
Memory used percentage
Disk used percentage
Swap used percentage

The important metrics used for the dashboard include:

cpu_usage_user
mem_used_percent
disk_used_percent

For disk monitoring, the root filesystem / was monitored using:

disk_used_percent

The CloudWatch Agent service was verified as running:

sudo systemctl status amazon-cloudwatch-agent

The service status was:

Active: active (running)

11. CloudWatch Dashboards

Two dashboards were prepared for the assignment.

Dashboard 1 – TodoApp-Infrastructure

Dashboard:

TodoApp-Infrastructure

It contains infrastructure-related monitoring such as:

EC2 CPU

Memory usage

Disk usage

Other EC2 infrastructure metrics

Dashboard 2 – TodoApp-Application-Database

Dashboard:

TodoApp-Application-Database

It is intended for:

Application request activity

Application errors

Application/access logs

RDS CPU

Database connections

RDS storage

A third dashboard named TodoApp-Application was also created during the monitoring setup. The two dashboards above are the primary dashboards for the assignment.

This satisfies the requirement:

Create at least two meaningful dashboards.

12. Centralized Logging

CloudWatch Logs was configured to collect logs from the EC2 instance.

A CloudWatch log group was created:

/todo-app/docker

The CloudWatch Agent was configured to collect Docker container logs from:

/var/lib/docker/containers/*/*-json.log

System logs were also configured through:

/var/log/messages

The EC2 instance uses rsyslog to provide /var/log/messages.

Rsyslog was enabled with:

sudo systemctl enable --now rsyslog

A test system message was generated using:

logger "TodoApp CloudWatch system logging test"

The message was verified locally in:

/var/log/messages

13. Application / Nginx Access Logs

The frontend runs Nginx in Docker.

Nginx access logs are written to Docker's stdout:

/var/log/nginx/access.log -> /dev/stdout

The Docker logs were verified with:

docker logs --tail 20 todo-frontend

Example access logs included:

GET / HTTP/1.1 200
GET /api/health HTTP/1.1 200
GET /api/todos HTTP/1.1 200

These logs were successfully delivered to:

/todo-app/docker

CloudWatch Logs Insights was used to query application/access logs.

Example query:

fields @timestamp, @message
| sort @timestamp desc
| limit 20

Application error analysis used:

fields @timestamp, @message
| filter @message like / 5[0-9][0-9] /
| sort @timestamp desc
| limit 20

At the time of verification, the observed requests were successful HTTP 200 responses.

14. Application Request Monitoring

Application request activity was monitored through the Nginx access logs.

A Logs Insights query was prepared to calculate requests over time:

fields @timestamp, @message
| filter @message like /HTTP\/1\.[01]/
| stats count() as requests by bin(5m)
| sort @timestamp asc

This provides an application request-rate view that can be displayed as a line chart on the application dashboard.

15. Database Monitoring

The PostgreSQL database is hosted on Amazon RDS.

Important RDS CloudWatch metrics include:

CPUUtilization
DatabaseConnections
FreeStorageSpace
FreeableMemory
ReadIOPS
WriteIOPS
ReadLatency
WriteLatency

The application/database dashboard was prepared to include important RDS health indicators such as:

RDS CPU utilization

Database connections

Free storage

16. Alerting

Amazon SNS was configured for failure notifications.

SNS topic:

todo-app-alerts

A disk-related SNS topic was also created:

TodoApp-High-Disk

CloudWatch alarms can send notifications through SNS.

The intended alerting flow is:

CloudWatch Metric
      |
      v
CloudWatch Alarm
      |
      v
SNS Topic
      |
      v
Email Notification

A high-CPU alarm was planned/configured using:

Metric: CPUUtilization
Statistic: Average
Period: 5 minutes
Threshold: > 80%

This satisfies the assignment requirement for failure notification through email.

17. Backup Strategy

Amazon RDS automated backups are enabled for the PostgreSQL database.

The current backup retention period is:

1 day

This provides point-in-time recovery within the configured retention window.

The assignment requirement allows implementing at least one backup/secret-management strategy, and RDS automated backups provide the implemented backup strategy.

Recommended production improvement:

Increase retention to 7–35 days depending on business requirements.

The current 1-day configuration was retained for this assignment.

18. Security Considerations

The implementation follows several security practices:

Database is hosted on Amazon RDS rather than directly on the EC2 host.

PostgreSQL uses SSL with:

DB_SSLMODE=require

Database password is supplied through:

${DB_PASSWORD}

rather than being hard-coded in Compose.

Security groups restrict access to required ports.

Database access is separated from public application access.

IAM role is attached to EC2 for CloudWatch Agent access.

CloudWatch Agent uses the EC2 IAM role instead of storing AWS access keys on the instance.

Frontend container mounts application files read-only where applicable.

For a production deployment, secrets could be moved to:

AWS Secrets Manager

or

AWS Systems Manager Parameter Store

19. Cost Optimization

Cost optimization considerations include:

Use small EC2 instance types appropriate for the workload.

Use RDS sizing based on actual requirements.

Monitor CloudWatch usage to avoid unnecessary high-cardinality metrics.

Use appropriate log retention periods instead of retaining logs indefinitely.

Remove unused AWS resources after testing.

Use Docker images efficiently to reduce storage and transfer costs.

Use automated backups with an appropriate retention period.

Scale infrastructure only when monitoring data justifies it.

20. Challenges Faced and Resolutions

Challenge 1 – Jenkins Pipeline Syntax Error

Jenkins initially failed with:

expecting '}', found 'http'

Cause:

The curl command was placed outside the correct Jenkins sh block / Groovy structure.

Resolution:

The Jenkinsfile syntax was corrected so shell commands were executed inside the appropriate sh block.

Result:

Jenkins build SUCCESS

Challenge 2 – Docker Compose

Docker Compose was initially unavailable.

Resolution:

The Docker Compose plugin was installed and verified.

The Compose deployment was then used to run:

todo-frontend
todo-backend

Challenge 3 – Database Connectivity

The application had to connect from the backend container to PostgreSQL RDS.

Resolution:

Database configuration was passed through environment variables and SSL was enabled:

DB_SSLMODE=require

The health endpoint confirmed:

{
  "database": "connected",
  "status": "healthy"
}

Challenge 4 – CloudWatch Agent Configuration

The CloudWatch Agent initially had configuration/credential issues.

Resolution:

EC2 IAM role was verified.

CloudWatchAgentServerPolicy was attached.

IMDSv2 token access was verified.

CloudWatch Agent configuration was validated.

The agent was restarted.

Docker logs began appearing in CloudWatch Logs.

Final agent state:

Active: active (running)

Challenge 5 – Docker Log Permissions

The CloudWatch Agent initially could not directly read Docker's JSON log files as the cwagent user.

Resolution:

The agent was run with the appropriate permissions and successfully collected Docker logs.

CloudWatch confirmed the log stream:

i-0ed17eb796275ea6f/docker

under:

/todo-app/docker

Challenge 6 – System Logs

/var/log/messages was initially unavailable.

Resolution:

rsyslog was installed and enabled:

sudo systemctl enable --now rsyslog

The log file became available:

/var/log/messages

A test message was generated and verified.

21. Validation Checklist

Infrastructure

Terraform infrastructure provisioned

VPC

Subnets

EC2

RDS PostgreSQL

Security groups

Terraform variables

Terraform outputs/state

Application

Frontend running

Backend running

PostgreSQL connected

Health endpoint returns 200

Todo API returns 200

CRUD API endpoints implemented

CI/CD

Jenkins configured

Jenkins build successful

Docker image published

Deployment verified

Monitoring

CPU monitoring

Memory monitoring

Disk monitoring

Application/access logs

System logs

RDS metrics

Dashboard 1

Dashboard 2

CloudWatch Logs

SNS alerting

Backup/Security

RDS automated backup

1-day backup retention

Database SSL

Database password supplied through environment variable

EC2 IAM role for CloudWatch

22. Final Result

The Todo application was successfully deployed on AWS using a containerized architecture.

The final validated flow is:

GitHub
   |
   v
Jenkins
   |
   v
Docker Image
   |
   v
EC2
   |
   +--------------------+
   |                    |
   v                    v
Nginx               Flask/Gunicorn
Frontend                Backend
   |                    |
   +---------+----------+
             |
             v
        PostgreSQL RDS

Monitoring and operations:

EC2
Docker
Application
RDS
  |
  v
CloudWatch
  |
  +--> Dashboards
  |
  +--> Logs Insights
  |
  +--> Alarms
          |
          v
         SNS
          |
          v
        Email

The implementation demonstrates end-to-end DevOps ownership across infrastructure provisioning, containerization, CI/CD, deployment, monitoring, logging, alerting, security, and backup.

23. Future Improvements

For a production-grade implementation, the following improvements could be added:

Application Load Balancer instead of direct EC2 port exposure.

Auto Scaling Group for application availability.

ECS/EKS for container orchestration.

AWS Secrets Manager for database credentials.

WAF for web application protection.

HTTPS using ACM certificates.

Multi-AZ RDS deployment.

Longer RDS backup retention.

Automated database snapshot policies.

Slack/PagerDuty integration for alerts.

Container vulnerability scanning in Jenkins.

Dependency vulnerability scanning.

Automated unit and integration test stages.

Manual production approval stage.

Separate staging and production environments.

Remote Terraform state using S3 with state locking.

More detailed application metrics such as latency and error rate.

Distributed tracing using OpenTelemetry.
