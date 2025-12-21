import json
import sys
import os
from datetime import datetime
import boto3

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.auth import get_user_context
from shared.response import error_response, success_response
from shared.utils import convert_floats_to_decimals

workout_table_name = os.environ['WORKOUT_TABLE']
dynamodb = boto3.resource('dynamodb')
workout_table = dynamodb.Table(workout_table_name)

def get_workouts(user_email: str, query_params: dict, request_id: str) -> dict:
    try:
        params = {
            'KeyConditionExpression': 'userEmail = :userEmail',
            'ExpressionAttributeValues': {':userEmail': user_email},
            'ScanIndexForward': False
        }
        
        if query_params:
            start_date = query_params.get('startDate')
            end_date = query_params.get('endDate')
            
            if start_date and end_date:
                params['KeyConditionExpression'] += ' AND workoutDate BETWEEN :startDate AND :endDate'
                params['ExpressionAttributeValues'][':startDate'] = start_date
                params['ExpressionAttributeValues'][':endDate'] = end_date
            elif start_date:
                params['KeyConditionExpression'] += ' AND workoutDate >= :startDate'
                params['ExpressionAttributeValues'][':startDate'] = start_date
        
        response = workout_table.query(**params)
        
        return success_response(200, {
            'workouts': response.get('Items', []),
            'count': response.get('Count', 0)
        })
    
    except Exception as e:
        print(f"Error getting workouts: {e}")
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def post_workout(user_email: str, body: dict, request_id: str) -> dict:
    try:
        if not body.get('workoutDate') or not body.get('sessionId') or not body.get('programWeek'):
            return error_response(400, 'VALIDATION_ERROR', 'Missing required fields', request_id)
        
        now = datetime.utcnow().isoformat() + 'Z'
        
        workout = {
            'userEmail': user_email,
            'workoutDate': body['workoutDate'],
            'programWeek': int(body['programWeek']),
            'sessionId': body['sessionId'],
            'mainLift': convert_floats_to_decimals(body.get('mainLift', {})),
            'circuit': convert_floats_to_decimals(body.get('circuit')),
            'notes': body.get('notes'),
            'duration': body.get('duration'),
            'createdAt': now
        }
        
        workout = {k: v for k, v in workout.items() if v is not None}
        
        workout_table.put_item(Item=workout)
        
        return success_response(200, workout)
    
    except Exception as e:
        print(f"Error posting workout: {e}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def handler(event, context):
    try:
        request_id = context.aws_request_id
        method = event['requestContext']['http']['method']
        
        user_context = get_user_context(event)
        if not user_context or not user_context.get('email'):
            return error_response(403, 'FORBIDDEN', 'Invalid or missing authentication', request_id)
        
        user_email = user_context['email']
        
        if method == 'GET':
            query_params = event.get('queryStringParameters')
            return get_workouts(user_email, query_params, request_id)
        
        if method == 'POST':
            body = json.loads(event.get('body', '{}'))
            return post_workout(user_email, body, request_id)
        
        return error_response(405, 'METHOD_NOT_ALLOWED', 'Method not allowed', request_id)
    
    except Exception as e:
        print(f"Handler error: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', context.aws_request_id)

