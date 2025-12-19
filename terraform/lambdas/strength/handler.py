import json
import sys
import os
from datetime import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.auth import get_user_id, get_user_context
from shared.dynamodb import data_table
from shared.response import error_response, success_response
from shared.validation import validate_strength, calculate_training_maxes

def get_strength(user_id: str, user_email: str, request_id: str) -> dict:
    try:
        response = data_table.get_item(
            Key={'userEmail': user_email, 'dataType': 'STRENGTH'}
        )
        
        item = response.get('Item')
        if not item:
            return error_response(404, 'NOT_FOUND', 'Strength data not found', request_id)
        
        item.pop('userEmail', None)
        item.pop('dataType', None)
        return success_response(200, item)
    
    except Exception as e:
        print(f"Error getting strength: {e}")
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def put_strength(user_id: str, user_email: str, body: dict, request_id: str) -> dict:
    try:
        is_valid, error_msg = validate_strength(body)
        if not is_valid:
            return error_response(400, 'VALIDATION_ERROR', error_msg, request_id)
        
        now = datetime.utcnow().isoformat() + 'Z'
        
        existing = data_table.get_item(
            Key={'userEmail': user_email, 'dataType': 'STRENGTH'}
        ).get('Item', {})
        
        training_maxes = calculate_training_maxes(body['oneRepMaxes'], body['tmPolicy'])
        
        strength = {
            'userEmail': user_email,
            'dataType': 'STRENGTH',
            'userId': user_id,
            'email': user_email,
            'oneRepMaxes': body['oneRepMaxes'],
            'tmPolicy': body['tmPolicy'],
            'trainingMaxes': training_maxes,
            'createdAt': existing.get('createdAt', now),
            'updatedAt': now
        }
        
        data_table.put_item(Item=strength)
        
        response_strength = {k: v for k, v in strength.items() if k not in ['userEmail', 'dataType']}
        return success_response(200, response_strength)
    
    except Exception as e:
        print(f"Error putting strength: {e}")
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def handler(event, context):
    try:
        print(f"Event: {json.dumps(event)}")
        request_id = context.aws_request_id
        method = event['requestContext']['http']['method']
        
        user_context = get_user_context(event)
        print(f"User context: {json.dumps(user_context)}")
        
        if not user_context or not user_context.get('userId') or not user_context.get('email'):
            return error_response(403, 'FORBIDDEN', 'Invalid or missing authentication', request_id)
        
        user_id = user_context['userId']
        user_email = user_context['email']
        
        if method == 'GET':
            return get_strength(user_id, user_email, request_id)
        
        if method == 'PUT':
            body = json.loads(event.get('body', '{}'))
            print(f"Body: {json.dumps(body)}")
            return put_strength(user_id, user_email, body, request_id)
        
        return error_response(405, 'METHOD_NOT_ALLOWED', 'Method not allowed', request_id)
    
    except Exception as e:
        print(f"Handler error: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', f'Internal server error: {str(e)}', context.aws_request_id)

