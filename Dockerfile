# Use official Python image as a parent image
FROM python:3.8-slim

# Install PostgreSQL development libraries and GCC for building psycopg2
RUN apt-get update && \
    apt-get install -y libpq-dev gcc

# Set the working directory
WORKDIR /app

# Copy the Python script into the container
COPY s3_to_rds_glue.py /app/

# Install necessary Python libraries
RUN pip install boto3 psycopg2 pandas

# Set environment variables for AWS region (optional)
ENV AWS_DEFAULT_REGION=your-region

# Define the command to run the Python script
CMD ["python", "s3_to_rds_glue.py"]
