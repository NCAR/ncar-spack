import boto3, sys

# Log into the S3 server
session = boto3.Session()
s3 = session.resource('s3')

# Get the bucket name
bucket_name = sys.argv[1]
cache_bucket = s3.Bucket(bucket_name)

for objects in cache_bucket.objects.filter(Prefix="build_cache/"):
    print(objects.key)
