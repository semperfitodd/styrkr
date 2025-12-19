import sys
import os
from datetime import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.response import success_response

def handler(event, context):
    return success_response(200, {
        'message': 'Hello from Styrkr API',
        'requestId': context.aws_request_id,
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    })

