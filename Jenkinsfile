pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        DOCKER_IMAGE = "s3-to-rds-glue-repository"
        ECR_REPOSITORY = "326310722410.dkr.ecr.us-east-1.amazonaws.com"
        AWS_ACCOUNT_ID = "326310722410"  // Your AWS Account ID
        ECR_URI = "${ECR_REPOSITORY}/${DOCKER_IMAGE}:latest"
        TF_WORKSPACE = "my-terraform-workspace"
    }

    stages {
        stage('Clone GitHub Repository') {
            steps {
                git 'https://github.com/pratikshaa-01/Go-Project'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build(DOCKER_IMAGE)
                }
            }
        }

        stage('Login to AWS ECR') {
            steps {
                script {
                    // Get AWS credentials from environment or Jenkins credentials plugin
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
                    }
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    // Tag and push the Docker image to ECR
                    sh "docker tag ${DOCKER_IMAGE} ${ECR_URI}"
                    sh "docker push ${ECR_URI}"
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    // Initialize Terraform workspace
                    sh "terraform init"
                    // Apply Terraform configuration to deploy AWS resources
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            terraform apply -auto-approve \
                            -var="aws_access_key=${AWS_ACCESS_KEY_ID}" \
                            -var="aws_secret_key=${AWS_SECRET_ACCESS_KEY}" \
                            -var="aws_region=${AWS_REGION}"
                        """
                    }
                }
            }
        }

        stage('Trigger Lambda') {
            steps {
                script {
                    // Trigger your Lambda function if necessary
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            aws lambda invoke \
                                --function-name S3ToRDSGlueFunction \
                                --region ${AWS_REGION} \
                                output.txt
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
