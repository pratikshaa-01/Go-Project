# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"  # Set your preferred AWS region
}

# Create a Random ID to ensure unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Create an S3 Bucket (removed ACL)
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-s3-bucket-terraform-${random_id.bucket_suffix.hex}"
}

# Upload a CSV file to the S3 bucket
resource "aws_s3_object" "csv_file" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "data-file.csv"
  acl    = "private"
  content = <<EOF
id,name,age
1,pratiksha Pawar,30
2,Madhavi gaikwad,25
3,Naina Pal,40
EOF
}

# IAM Role for Lambda with permissions for S3, RDS, and Glue
resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_rds_glue_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the S3 Full Access policy to the Lambda role
resource "aws_iam_policy_attachment" "lambda_s3_policy_attachment" {
  name       = "lambda-s3-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  roles      = [aws_iam_role.lambda_role.name]
}

# Attach the Glue Service Role policy to the Lambda role
resource "aws_iam_policy_attachment" "glue_policy_attachment" {
  name       = "lambda-glue-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  roles      = [aws_iam_role.lambda_role.name]
}

# Attach a custom RDS policy to the Lambda role 
resource "aws_iam_policy" "rds_policy" {
  name        = "lambda-rds-policy"
  description = "Lambda access to RDS instances"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "rds:DescribeDBInstances",
          "rds:Connect"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_rds_policy_attachment" {
  name       = "lambda-rds-policy-attachment"
  policy_arn = aws_iam_policy.rds_policy.arn
  roles      = [aws_iam_role.lambda_role.name]
}

# Create an RDS MySQL Instance 
resource "aws_db_instance" "my_rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "mysecurepassword"
  parameter_group_name = "default.mysql8.0"
  multi_az             = false
  publicly_accessible  = true  # Public access enabled
  skip_final_snapshot  = true
  identifier           = "my-rds-instance"
  db_name              = "mydatabase"

  tags = {
    Name = "My RDS Instance"
  }
}

# Create Glue Database
resource "aws_glue_catalog_database" "my_glue_db" {
  name = "my_glue_database"
}

# Lambda Function (uses Docker image from ECR)
resource "aws_lambda_function" "my_lambda" {
  function_name = "S3ToRDSGlueFunction"
  role          = aws_iam_role.lambda_role.arn
  image_uri     = "you-AWS-Account-id.dkr.ecr.us-east-1.amazonaws.com/s3-to-rds-glue-repository:latest"

  environment {
    variables = {
      S3_BUCKET   = aws_s3_bucket.my_bucket.bucket
      RDS_HOST    = aws_db_instance.my_rds.endpoint
      RDS_PORT    = "3306"  # MySQL default port
      DB_NAME     = "mydatabase"
      DB_USER     = "admin"
      DB_PASS     = "mysecurepassword"
      GLUE_DB     = aws_glue_catalog_database.my_glue_db.name
    }
  }

  # No need for handler and runtime when using Docker image
  package_type = "Image"
}

# Output Lambda function name
output "lambda_function_name" {
  value = aws_lambda_function.my_lambda.function_name
}
