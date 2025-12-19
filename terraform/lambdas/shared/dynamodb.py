import os
import boto3

dynamodb = boto3.resource('dynamodb')
DATA_TABLE_NAME = os.environ.get('DATA_TABLE', '')
data_table = dynamodb.Table(DATA_TABLE_NAME) if DATA_TABLE_NAME else None

