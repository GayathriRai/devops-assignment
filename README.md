# DevOps Assignment – Todo Application

## Project Overview

This project demonstrates an end-to-end DevOps implementation for a Todo application using AWS, Terraform, Docker, Jenkins, PostgreSQL RDS, Amazon CloudWatch, and Amazon SNS.

### Technology Stack

- Frontend: Nginx
- Backend: Flask + Gunicorn
- Database: PostgreSQL on Amazon RDS
- Infrastructure: AWS + Terraform
- CI/CD: Jenkins
- Containerization: Docker / Docker Compose
- Registry: Docker Hub
- Monitoring: Amazon CloudWatch
- Logging: CloudWatch Logs
- Alerting: CloudWatch Alarms + Amazon SNS
- Backup: Amazon RDS automated backups

The application was successfully deployed and verified on AWS.

## Architecture

```text
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
User ---> ALB ---> Nginx             |
          :80      Frontend           |
                     |                |
                     v                |
                 Flask Backend        |
                  :5000               |
                     |                |
                     v                |
                PostgreSQL RDS        |
                  :5432               |
                  +-------------------+

Monitoring:
EC2 / Docker / Application / RDS
              |
              v
        Amazon CloudWatch
          |           |
     Dashboards      Alarms
                       |
                       v
                     SNS
                       |
                       v
                     Email
```

## Repository

GitHub repository:

`https://github.com/GayathriRai/devops-assignment`

### Repository Structure

```text
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
    ├── providers.tf
    └── awsserver.pub
```

## AWS Infrastructure

Terraform provisions and manages:

- VPC
- Internet Gateway
- Public subnets
- Private subnets
- Public and private route tables
- NAT Gateway
- Elastic IP
- EC2 instance
- Application Load Balancer
- ALB target group
- ALB listener
- Security groups
- Amazon RDS PostgreSQL
- RDS subnet group

### Network Design

```text
Internet
   |
   v
Application Load Balancer
   |
   v
EC2 Application Server
   |
   +---- Nginx Frontend
   |
   +---- Flask/Gunicorn Backend
              |
              v
        PostgreSQL RDS
```

The EC2 instance is in a public subnet. RDS is deployed in private subnets and is not publicly accessible.

## Terraform

Terraform is used as Infrastructure as Code.

### Workflow

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

### Verify Resources

```bash
terraform state list
terraform output
```

### ALB DNS

```bash
terraform output -raw alb_dns_name
```

Example:

```text
todo-app-alb-1415922835.ap-south-1.elb.amazonaws.com
```

### ALB Target Health

The target group uses port 8080 and checks:

```text
/api/health
```

The EC2 target was successfully verified as:

```text
State: healthy
Port: 8080
```

## Application

The application contains an Nginx frontend and Flask backend.

### Frontend

Nginx serves the Todo UI and proxies API requests to the Flask backend.

### Backend

The Flask application runs with Gunicorn on port 5000.

### API Endpoints

```text
GET    /api/health
GET    /api/todos
POST   /api/todos
PUT    /api/todos/<todo_id>
DELETE /api/todos/<todo_id>
```

## Database

PostgreSQL is hosted on Amazon RDS.

### Environment Variables

```text
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASSWORD
DB_SSLMODE
```

SSL is enabled:

```text
DB_SSLMODE=require
```

The database password is supplied through an environment variable and is not hard-coded in Docker Compose.

### RDS Configuration

```text
Engine: PostgreSQL
Version: 16
Instance Class: db.t4g.micro
Storage: 20 GB
Maximum Storage: 50 GB
Storage Type: gp3
Encryption: Enabled
Publicly Accessible: No
Port: 5432
Backup Retention: 1 day
```

## Docker

Docker is used to containerize the application.

Expected containers:

```text
todo-frontend
todo-backend
```

### Backend Image

```text
gayathrirai/todo-app-backend-new:latest
```

### Frontend Image

```text
nginx:alpine
```

### Verify Containers

```bash
docker ps
```

### View Logs

```bash
docker logs --tail 20 todo-frontend
docker logs --tail 20 todo-backend
```

## Application Verification

### Frontend

```bash
curl -i http://<ALB_DNS_NAME>/
```

Expected:

```text
HTTP/1.1 200 OK
```

### Health Endpoint

```bash
curl -i http://<ALB_DNS_NAME>/api/health
```

Expected:

```json
{
  "database": "connected",
  "status": "healthy"
}
```

### Todo API

```bash
curl -i http://<ALB_DNS_NAME>/api/todos
```

Expected:

```text
HTTP/1.1 200 OK
```

End-to-end flow:

```text
User
 |
 v
ALB
 |
 v
Nginx
 |
 v
Flask / Gunicorn
 |
 v
PostgreSQL RDS
```

## Application Load Balancer

An Application Load Balancer was implemented using Terraform.

### ALB

```text
Name: todo-app-alb
Protocol: HTTP
Port: 80
```

### Target Group

```text
Name: todo-app-tg
Protocol: HTTP
Port: 8080
Target Type: Instance
```

### Health Check

```text
Path: /api/health
Port: 8080
Protocol: HTTP
Expected Status: 200
Healthy Threshold: 2
Unhealthy Threshold: 3
Timeout: 5 seconds
Interval: 30 seconds
```

The EC2 target was verified as healthy.

## CI/CD with Jenkins

Jenkins automates the application delivery process.

### Pipeline

```text
Developer
    |
    v
GitHub
    |
    v
Jenkins
    |
    +--> Checkout
    |
    +--> Build
    |
    +--> Test
    |
    +--> Docker Build
    |
    +--> Docker Push
    |
    +--> Deploy to EC2
    |
    +--> Verify
    |
    v
Running Application
```

The Jenkins build completed successfully:

```text
SUCCESS
```

A Jenkins Groovy syntax error was encountered during development:

```text
MultipleCompilationErrorsException
expecting '}', found 'http'
```

The issue was caused by a shell `curl` command being outside the correct `sh` block. The Jenkinsfile was corrected and the build succeeded.

## Docker Hub

Backend image:

```text
gayathrirai/todo-app-backend-new:latest
```

The EC2 instance successfully pulled and ran the image.

## Monitoring

Amazon CloudWatch monitors infrastructure, application, logs, and RDS.

### EC2 Metrics

The CloudWatch Agent collects:

```text
CPU usage
Memory usage
Disk usage
Swap usage
```

Important metrics:

```text
cpu_usage_user
mem_used_percent
disk_used_percent
```

Root filesystem monitoring:

```text
disk_used_percent
```

CloudWatch Agent status was verified as:

```text
Active: active (running)
```

The EC2 IAM role provides CloudWatch permissions without storing AWS access keys on the instance.

## CloudWatch Dashboards

### Dashboard 1 – TodoApp-Infrastructure

Includes:

- EC2 CPU
- Memory usage
- Disk usage
- Infrastructure metrics

### Dashboard 2 – TodoApp-Application-Database

Includes:

- Application request activity
- Application errors
- Application/access logs
- RDS CPU
- Database connections
- RDS storage

An additional `TodoApp-Application` dashboard was also created during setup.

These dashboards satisfy the requirement for at least two meaningful dashboards.

## Centralized Logging

CloudWatch Logs collects logs from EC2 and Docker.

### Log Group

```text
/todo-app/docker
```

### Docker Logs

```text
/var/lib/docker/containers/*/*-json.log
```

### System Logs

```text
/var/log/messages
```

Rsyslog was enabled with:

```bash
sudo systemctl enable --now rsyslog
```

Test message:

```bash
logger "TodoApp CloudWatch system logging test"
```

The message was verified locally and collected by CloudWatch.

## Nginx Access Logs

Nginx writes access logs to Docker stdout.

Example:

```text
/var/log/nginx/access.log -> /dev/stdout
```

Logs were verified using:

```bash
docker logs --tail 20 todo-frontend
```

Example requests:

```text
GET / HTTP/1.1 200
GET /api/health HTTP/1.1 200
GET /api/todos HTTP/1.1 200
```

## CloudWatch Logs Insights

### Recent Logs

```text
fields @timestamp, @message
| sort @timestamp desc
| limit 20
```

### HTTP Error Analysis

```text
fields @timestamp, @message
| filter @message like / 5[0-9][0-9] /
| sort @timestamp desc
| limit 20
```

### Request Rate

```text
fields @timestamp, @message
| filter @message like /HTTP\/1\.[01]/
| stats count() as requests by bin(5m)
| sort @timestamp asc
```

Application requests were verified as successful HTTP 200 responses.

## RDS Monitoring

Important RDS CloudWatch metrics:

```text
CPUUtilization
DatabaseConnections
FreeStorageSpace
FreeableMemory
ReadIOPS
WriteIOPS
ReadLatency
WriteLatency
```

The application/database dashboard includes important database health indicators.

## Alerting

CloudWatch alarms and Amazon SNS provide failure notifications.

### SNS Topics

```text
todo-app-alerts
TodoApp-High-Disk
```

### Alert Flow

```text
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
```

### High CPU Alarm

```text
Metric: CPUUtilization
Statistic: Average
Period: 5 minutes
Threshold: > 80%
```

This provides email notification when CPU utilization exceeds the configured threshold.

## Backup Strategy

Amazon RDS automated backups are enabled.

Current configuration:

```text
Backup Retention: 1 day
```

This provides point-in-time recovery within the configured retention window.

For production, the retention period can be increased to 7–35 days depending on requirements.

## Security

Security practices implemented:

- RDS is not publicly accessible.
- RDS is placed in private subnets.
- PostgreSQL traffic is restricted through security groups.
- ALB accepts public HTTP traffic.
- EC2 application traffic is restricted to the ALB security group.
- PostgreSQL uses SSL.
- `DB_SSLMODE=require` is configured.
- Database password is supplied through an environment variable.
- EC2 uses an IAM role for CloudWatch access.
- AWS access keys are not stored on EC2.

### Production Recommendations

Use:

```text
AWS Secrets Manager
```

or:

```text
AWS Systems Manager Parameter Store
```

for database credentials.

Enable HTTPS using:

```text
AWS Certificate Manager
```

## Cost Optimization

- Use small EC2 instance types for development.
- Size RDS according to workload.
- Use appropriate CloudWatch log retention.
- Avoid unnecessary monitoring metrics.
- Remove unused AWS resources after testing.
- Use efficient Docker images.
- Use appropriate RDS backup retention.
- Scale based on monitoring data.

## Challenges and Resolutions

### Jenkins Pipeline Syntax

**Problem:**

```text
expecting '}', found 'http'
```

**Resolution:** Corrected Jenkinsfile shell block structure.

**Result:** Jenkins build succeeded.

### Docker Compose

Docker Compose was initially unavailable.

**Resolution:** Docker Compose plugin was installed and verified.

### Database Connectivity

The backend needed to connect to RDS PostgreSQL.

**Resolution:** Database settings were supplied through environment variables and SSL was enabled.

Health check confirmed:

```json
{
  "database": "connected",
  "status": "healthy"
}
```

### CloudWatch Agent

The CloudWatch Agent initially had configuration and permission issues.

**Resolution:**

- Verified EC2 IAM role.
- Attached `CloudWatchAgentServerPolicy`.
- Verified IMDSv2 access.
- Validated agent configuration.
- Restarted the agent.

Final state:

```text
Active: active (running)
```

### Docker Log Permissions

The CloudWatch Agent initially could not read Docker JSON log files.

**Resolution:** Appropriate permissions were configured and Docker logs were successfully collected.

### System Logs

`/var/log/messages` was initially unavailable.

**Resolution:** Rsyslog was installed and enabled.

### ALB Target Health

The ALB health check uses:

```text
/api/health
```

on port:

```text
8080
```

The EC2 target was verified as:

```text
healthy
```

## Validation Checklist

### Infrastructure

- [x] Terraform infrastructure provisioned
- [x] VPC
- [x] Public subnets
- [x] Private subnets
- [x] Internet Gateway
- [x] NAT Gateway
- [x] EC2
- [x] RDS PostgreSQL
- [x] Security groups
- [x] Application Load Balancer
- [x] Target group
- [x] ALB listener
- [x] Terraform variables
- [x] Terraform outputs/state

### Application

- [x] Frontend running
- [x] Backend running
- [x] PostgreSQL connected
- [x] Health endpoint returns 200
- [x] Todo API returns 200
- [x] CRUD endpoints implemented
- [x] ALB target health verified

### CI/CD

- [x] Jenkins configured
- [x] Jenkins build successful
- [x] Docker image published
- [x] Deployment verified

### Monitoring

- [x] CPU monitoring
- [x] Memory monitoring
- [x] Disk monitoring
- [x] Docker logs
- [x] Nginx access logs
- [x] System logs
- [x] RDS metrics
- [x] CloudWatch Dashboard 1
- [x] CloudWatch Dashboard 2
- [x] CloudWatch Logs
- [x] SNS alerting

### Backup and Security

- [x] RDS automated backup
- [x] 1-day backup retention
- [x] Database SSL
- [x] Database password through environment variable
- [x] EC2 IAM role for CloudWatch
- [x] RDS not publicly accessible
- [x] ALB-based application access

## Final Result

The Todo application was successfully deployed on AWS using a containerized DevOps architecture.

```text
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
```

Monitoring and operations:

```text
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
```

### Verified ALB

```text
todo-app-alb-1415922835.ap-south-1.elb.amazonaws.com
```

The ALB was successfully created, the EC2 target was healthy, and the TaskFlow frontend returned HTTP 200.

## Future Improvements

- Auto Scaling Group
- Multiple application instances
- ECS/EKS
- AWS Secrets Manager
- AWS WAF
- HTTPS using ACM
- Multi-AZ RDS
- Longer backup retention
- Automated database snapshots
- Slack/PagerDuty alert integration
- Container vulnerability scanning
- Dependency vulnerability scanning
- Automated unit and integration tests
- Manual production approval
- Separate staging and production environments
- Remote Terraform state using S3 with state locking
- Application latency monitoring
- Application error-rate monitoring
- OpenTelemetry distributed tracing

## Conclusion

This project demonstrates end-to-end DevOps ownership across:

```text
Infrastructure as Code
        +
Containerization
        +
CI/CD
        +
AWS Deployment
        +
Load Balancing
        +
Database Management
        +
Monitoring
        +
Centralized Logging
        +
Alerting
        +
Security
        +
Backup
```

The final implementation demonstrates a production-oriented AWS DevOps workflow for a containerized Todo application.
