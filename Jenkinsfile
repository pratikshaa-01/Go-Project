pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        DOCKER_IMAGE = "s3-to-rds-glue-repository"
        ECR_REPOSITORY = "326310722410.dkr.ecr.us-east-1.amazonaws.com"
        AWS_ACCOUNT_ID = "326310722410"
        ECR_URI = "${ECR_REPOSITORY}/${DOCKER_IMAGE}:latest"
        TF_WORKSPACE = "my-terraform-workspace"
    }

    stages {
        stage('Clone GitHub Repository') {
            steps {
                git 'https://github.com/pratikshaa-01/Go-Project.git'
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
                    // Login to AWS ECR using AWS CLI with AWS credentials
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
                        try {
                            echo "Logging in to AWS ECR in region ${AWS_REGION}"

                            // Login to AWS ECR using AWS CLI
                            sh """
                                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}
                            """
                            echo "Login successful!"
                        } catch (Exception e) {
                            echo "Error during AWS ECR login: ${e.getMessage()}"
                            currentBuild.result = 'FAILURE'
                            error("AWS ECR login failed!")
                        }
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
                    
                    // Validate the Terraform files before applying
                    sh "terraform validate"

                    // Apply Terraform configuration to deploy AWS resources
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
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
                    // Trigger Lambda function if necessary
                    withAWS(credentials: 'aws-credentials', region: AWS_REGION) {
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
