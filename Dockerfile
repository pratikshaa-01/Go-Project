FROM python:3.8-slim

RUN apt-get update && \
    apt-get install -y libpq-dev gcc

WORKDIR /app

COPY s3_to_rds_glue.py /app/

RUN pip install boto3 psycopg2 pandas

CMD ["python", "s3_to_rds_glue.py"]
