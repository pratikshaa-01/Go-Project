import boto3
import pandas as pd
import psycopg2
from botocore.exceptions import ClientError

# AWS clients
s3_client = boto3.client('s3')
glue_client = boto3.client('glue')

# RDS connection parameters
rds_host = 'your-rds-endpoint'
rds_db = 'your-db'
rds_user = 'your-username'
rds_password = 'your-password'

def fetch_s3_data(bucket, key):
    try:
        response = s3_client.get_object(Bucket=bucket, Key=key)
        data = pd.read_csv(response['Body'])
        return data
    except ClientError as e:
        print(f"Error fetching from S3: {e}")
        return None

def load_to_rds(data):
    try:
        conn = psycopg2.connect(
            host=rds_host,
            dbname=rds_db,
            user=rds_user,
            password=rds_password
        )
        cursor = conn.cursor()
        for row in data.itertuples():
            cursor.execute(f"INSERT INTO your_table (col1, col2) VALUES (%s, %s)", (row.col1, row.col2))
        conn.commit()
        cursor.close()
        conn.close()
        print("Data loaded to RDS successfully.")
    except Exception as e:
        print(f"Error loading to RDS: {e}")
        return False
    return True

def load_to_glue(data):
    try:
        # Start Glue job
        job_name = 'your-glue-job-name'
        glue_client.start_job_run(JobName=job_name)
        print("Data sent to Glue.")
    except ClientError as e:
        print(f"Error starting Glue job: {e}")

def main():
    s3_bucket = 'your-s3-bucket'
    s3_key = 'your-s3-key.csv'

    data = fetch_s3_data(s3_bucket, s3_key)
    if data is not None:
        if not load_to_rds(data):
            load_to_glue(data)

if __name__ == "__main__":
    main()
