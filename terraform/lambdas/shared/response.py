import json
from typing import Any

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
        'body': json.dumps(data, default=str)
    }

