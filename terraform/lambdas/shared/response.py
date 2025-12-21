import json
from typing import Any
from decimal import Decimal

class DecimalEncoder(json.JSONEncoder):
    """Custom JSON encoder that converts Decimal to float"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def error_response(status_code: int, code: str, message: str, request_id: str) -> dict:
    return {
        'statusCode': status_code,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({
            'error': {
                'code': code,
                'message': message,
                'requestId': request_id
            }
        })
    }

def success_response(status_code: int, data: Any) -> dict:
    return {
        'statusCode': status_code,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(data, cls=DecimalEncoder)
    }

