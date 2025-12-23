import sys
import os
from datetime import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.dynamodb import data_table
from shared.response import error_response, success_response
from shared.utils import convert_floats_to_decimals
from shared.handler_utils import handle_request

DATA_TYPE = 'SCHEDULE'

def get_schedule(user_context: dict, query_params: dict, request_id: str, event: dict) -> dict:
    try:
        response = data_table.get_item(
            Key={'userEmail': user_context['email'], 'dataType': DATA_TYPE}
        )
        
        item = response.get('Item')
        if not item:
            return error_response(404, 'NOT_FOUND', 'Schedule customizations not found', request_id)
        
        item.pop('userEmail', None)
        item.pop('dataType', None)
        
        return success_response(200, item)
    except Exception as e:
        print(f"Error getting schedule: {e}")
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def put_schedule(user_context: dict, body: dict, request_id: str, event: dict) -> dict:
    try:
        now = datetime.utcnow().isoformat() + 'Z'
        user_email = user_context['email']
        
        existing = data_table.get_item(
            Key={'userEmail': user_email, 'dataType': DATA_TYPE}
        ).get('Item', {})
        
        schedule = {
            'userEmail': user_email,
            'dataType': DATA_TYPE,
            'userId': user_context['userId'],
            'daySwaps': convert_floats_to_decimals(body.get('daySwaps', {})),
            'dayAssignments': body.get('dayAssignments', {}),
            'createdAt': existing.get('createdAt', now),
            'updatedAt': now
        }
        
        data_table.put_item(Item=schedule)
        
        return success_response(200, {k: v for k, v in schedule.items() if k not in ['userEmail', 'dataType']})
    except Exception as e:
        print(f"Error putting schedule: {e}")
        return error_response(500, 'INTERNAL', 'Internal server error', request_id)

def handler(event, context):
    return handle_request(event, context, get_handler=get_schedule, put_handler=put_schedule)

