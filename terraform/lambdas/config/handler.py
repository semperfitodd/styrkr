import json
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.response import success_response, error_response
from shared.s3_config import get_app_config

def get_template(request_id: str) -> dict:
    """Get program template from S3 (no auth required)."""
    try:
        template = get_app_config('config/plan.template.json')
        return success_response(200, template)
    except Exception as e:
        print(f"Error fetching template: {e}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Failed to fetch program template', request_id)

def get_exercises(request_id: str) -> dict:
    """Get exercise library from S3 (no auth required)."""
    try:
        exercises = get_app_config('config/exercises.latest.json')
        return success_response(200, exercises)
    except Exception as e:
        print(f"Error fetching exercises: {e}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Failed to fetch exercise library', request_id)

def handler(event, context):
    """
    Handle public config endpoints (no authentication required).
    
    Routes:
    - GET /program/template
    - GET /exercises
    """
    try:
        request_id = context.aws_request_id
        path = event.get('rawPath', '')
        method = event['requestContext']['http']['method']
        
        print(f"Config request: {method} {path}")
        
        if method == 'GET' and path == '/program/template':
            return get_template(request_id)
        
        if method == 'GET' and path == '/exercises':
            return get_exercises(request_id)
        
        return error_response(404, 'NOT_FOUND', 'Endpoint not found', request_id)
    
    except Exception as e:
        print(f"Handler error: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', context.aws_request_id)

