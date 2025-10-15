import boto3, sys, re

# Get the bucket name
try:
    bucket_name = sys.argv[1]
except KeyError:
    print("Usage: spack python list_cache_s3.py BUCKET [PROFILE]")
    raise

if len(sys.argv) == 3:
    s3_profile = sys.argv[2]
    session = boto3.Session(profile_name = s3_profile)
else:
    session = boto3.Session()

# Log into the S3 server
s3 = session.resource('s3')
cache_bucket = s3.Bucket(bucket_name)

for obj in cache_bucket.objects.filter(Prefix = "v3/manifests/spec"):
    if obj.key.endswith(".spec.manifest.json"):
        try:
            print(re.search(r".*/(.*).spec.manifest.json", obj.key).group(1))
        except:
            pass
