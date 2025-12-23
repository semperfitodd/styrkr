import json
import sys
import os
from datetime import datetime
import boto3

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.response import success_response, error_response
from shared.jwt_validator import validate_user_context, get_dynamodb_user_key
from shared.utils import convert_floats_to_decimals

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DATA_TABLE']
data_table = dynamodb.Table(table_name)

def get_settings(user_id: str, request_id: str) -> dict:
    """Get program settings for user."""
    try:
        pk = get_dynamodb_user_key(user_id)
        
        response = data_table.get_item(
            Key={'userEmail': pk, 'dataType': 'PROGRAM_SETTINGS'}
        )
        
        if 'Item' not in response:
            return error_response(404, 'NOT_FOUND', 'Program settings not found', request_id)
        
        return success_response(200, response['Item'])
    
    except Exception as e:
        print(f"Error getting settings: {e}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def save_settings(user_id: str, body: dict, request_id: str) -> dict:
    """Save program settings for user."""
    try:
        pk = get_dynamodb_user_key(user_id)
        now = datetime.utcnow().isoformat() + 'Z'
        
        # Required fields
        required_fields = ['trainingDaysPerWeek', 'preferredUnits']
        for field in required_fields:
            if field not in body:
                return error_response(400, 'VALIDATION_ERROR', f'Missing required field: {field}', request_id)
        
        settings = {
            'userEmail': pk,
            'dataType': 'PROGRAM_SETTINGS',
            'trainingDaysPerWeek': int(body['trainingDaysPerWeek']),
            'preferredUnits': body['preferredUnits'],
            'preferredStartDay': body.get('preferredStartDay', 'mon'),
            'nonLiftingDayMode': body.get('nonLiftingDayMode', 'gpp'),
            'conditioningLevel': body.get('conditioningLevel', 'moderate'),
            'equipment': body.get('equipment', []),
            'constraints': body.get('constraints', []),
            'rounding': body.get('rounding', 5),
            'tmPercent': body.get('tmPercent', 85),
            'exercisePreferences': convert_floats_to_decimals(body.get('exercisePreferences', {})),
            'updatedAt': now
        }
        
        # Add createdAt if new
        existing = data_table.get_item(
            Key={'userEmail': pk, 'dataType': 'PROGRAM_SETTINGS'}
        )
        if 'Item' not in existing:
            settings['createdAt'] = now
        
        data_table.put_item(Item=settings)
        
        return success_response(200, settings)
    
    except Exception as e:
        print(f"Error saving settings: {e}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def handler(event, context):
    """
    Handle program settings endpoints (requires authentication).
    
    Routes:
    - GET /program/settings
    - POST /program/settings
    """
    try:
        request_id = context.aws_request_id
        method = event['requestContext']['http']['method']
        
        # Validate JWT and extract user context
        try:
            user_context = validate_user_context(event)
            user_id = user_context['userId']
        except ValueError as e:
            return error_response(403, 'FORBIDDEN', str(e), request_id)
        
        if method == 'GET':
            return get_settings(user_id, request_id)
        
        if method == 'POST':
            body = json.loads(event.get('body', '{}'))
            return save_settings(user_id, body, request_id)
        
        return error_response(405, 'METHOD_NOT_ALLOWED', 'Method not allowed', request_id)
    
    except Exception as e:
        print(f"Handler error: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', context.aws_request_id)

