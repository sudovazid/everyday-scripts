import logging
import boto3

s3 = boto3.resource('s3')

def list_bucket():
    print('Existing buckets:')
    for bucket in s3.buckets.all():
        print(f"Name: {bucket.name}")


print(list_bucket())
