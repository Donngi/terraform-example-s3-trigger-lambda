import urllib
import boto3
import os


def lambda_handler(event, context):
    print(event)

    client = boto3.client('s3')

    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(
        event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    try:
        # Get object
        print('Start to get object')
        response = client.get_object(Bucket=bucket, Key=key)
        print(response)

        # Put object
        print('Start to put object')
        response = client.put_object(
            Bucket=os.getenv('REPLICA_S3_NAME'), Key=key)
        print(response)

    except Exception as e:
        print(e)
        print('Failed to copy object.')
        raise e

    return {
        'statusCode': 200,
        'body': 'Success'
    }
