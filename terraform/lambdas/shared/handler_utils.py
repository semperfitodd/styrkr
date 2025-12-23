import json
import traceback
from shared.auth import get_user_context
from shared.response import error_response

def handle_request(event, context, get_handler=None, post_handler=None, put_handler=None, require_user_id=True):
    try:
        request_id = context.aws_request_id
        method = event['requestContext']['http']['method']
        
        user_context = get_user_context(event)
        
        required_fields = ['email']
        if require_user_id:
            required_fields.append('userId')
        
        if not user_context or not all(user_context.get(field) for field in required_fields):
            return error_response(403, 'FORBIDDEN', 'Invalid or missing authentication', request_id)
        
        handlers = {
            'GET': get_handler,
            'POST': post_handler,
            'PUT': put_handler
        }
        
        handler = handlers.get(method)
        if not handler:
            return error_response(405, 'METHOD_NOT_ALLOWED', 'Method not allowed', request_id)
        
        if method in ['POST', 'PUT']:
            body = json.loads(event.get('body', '{}'))
            return handler(user_context, body, request_id, event)
        elif method == 'GET':
            query_params = event.get('queryStringParameters')
            return handler(user_context, query_params, request_id, event)
        
    except Exception as e:
        print(f"Handler error: {type(e).__name__}: {str(e)}")
        traceback.print_exc()
        return error_response(500, 'INTERNAL', 'Internal server error', context.aws_request_id)

