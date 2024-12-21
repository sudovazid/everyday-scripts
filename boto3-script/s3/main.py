import logging
import boto3
import botocode.exceptions import ClientError

def create_bucket(bucket_name, region=None):
    try:
        if region is None:
            s3_client = boto3.client('s3')
            s3_client.create_bucket(Bucket=bucket_name)
        else:
            s3_client = boto3.client('s3', region_name=region)
            location = {'LocationConstraint': region}
            s3_client.create_bucket(Bucket=bucket_name, CreateBucketConfiguration=location)
    except ClientError as e:
        logging.error(e)
        return False

def list_bucket():
    s3 = boto3.client('s3')
    response = s3.list_bucket()

    print('Existing buckets:')
    for bucket in response['Buckets']:
        print(f'{bucket["Name"]'}


list_bucket()
print()
