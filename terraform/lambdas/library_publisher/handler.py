import json
import sys
import os
import boto3
import hashlib
import time
from datetime import datetime, timezone
from decimal import Decimal

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from shared.auth import get_user_context
from shared.response import error_response, success_response

# Environment variables
CONFIG_TABLE_NAME = os.environ['CONFIG_TABLE_NAME']
CONFIG_BUCKET_NAME = os.environ['CONFIG_BUCKET_NAME']
CONFIG_PREFIX = os.environ.get('CONFIG_PREFIX', 'config/')
DEBOUNCE_SECONDS = int(os.environ.get('DEBOUNCE_SECONDS', '30'))

# AWS clients
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
config_table = dynamodb.Table(CONFIG_TABLE_NAME)

# Constants
LIBRARY_PK = "LIBRARY#EXERCISES"
META_PK = "LIBRARY#META"
META_SK = "CURRENT"
DEBOUNCE_KEY = "LIBRARY#DEBOUNCE"

def decimal_default(obj):
    """JSON serializer for Decimal objects"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")

def canonical_json(obj):
    """Generate canonical JSON for consistent hashing"""
    return json.dumps(obj, sort_keys=True, separators=(',', ':'), default=decimal_default)

def compute_etag(data):
    """Compute SHA256 hash of canonical JSON"""
    canonical = canonical_json(data)
    return hashlib.sha256(canonical.encode('utf-8')).hexdigest()

def get_all_exercises():
    """Query all exercises from DynamoDB"""
    try:
        print(f"Querying exercises from table {CONFIG_TABLE_NAME}")
        response = config_table.query(
            KeyConditionExpression='PK = :pk',
            ExpressionAttributeValues={':pk': LIBRARY_PK}
        )
        
        exercises = response.get('Items', [])
        print(f"Found {len(exercises)} exercises")
        
        # Remove DynamoDB keys from exercises
        cleaned_exercises = []
        for ex in exercises:
            cleaned = {k: v for k, v in ex.items() if k not in ['PK', 'SK', 'type']}
            cleaned_exercises.append(cleaned)
        
        return cleaned_exercises
    except Exception as e:
        print(f"Error querying exercises: {e}")
        raise

def get_meta():
    """Get current meta information"""
    try:
        response = config_table.get_item(
            Key={'PK': META_PK, 'SK': META_SK}
        )
        return response.get('Item', {
            'PK': META_PK,
            'SK': META_SK,
            'version': 0,
            'lastPublishedAt': None,
            'etag': None,
            'latestKey': None,
            'versionedKey': None
        })
    except Exception as e:
        print(f"Error getting meta: {e}")
        return {
            'PK': META_PK,
            'SK': META_SK,
            'version': 0,
            'lastPublishedAt': None,
            'etag': None,
            'latestKey': None,
            'versionedKey': None
        }

def update_meta(version, etag, latest_key, versioned_key):
    """Update meta information in DynamoDB"""
    now = datetime.now(timezone.utc).isoformat()
    
    try:
        config_table.put_item(
            Item={
                'PK': META_PK,
                'SK': META_SK,
                'version': version,
                'lastPublishedAt': now,
                'etag': etag,
                'latestKey': latest_key,
                'versionedKey': versioned_key,
                'updatedAt': now
            }
        )
        print(f"Updated meta to version {version}")
    except Exception as e:
        print(f"Error updating meta: {e}")
        raise

def publish_to_s3(key, payload, cache_control):
    """Write JSON payload to S3 with cache headers"""
    try:
        s3.put_object(
            Bucket=CONFIG_BUCKET_NAME,
            Key=key,
            Body=json.dumps(payload, indent=2, default=decimal_default),
            ContentType='application/json',
            CacheControl=cache_control
        )
        print(f"Published to s3://{CONFIG_BUCKET_NAME}/{key}")
    except Exception as e:
        print(f"Error publishing to S3: {e}")
        raise

def get_slot_taxonomy():
    """Return the slot taxonomy for the program"""
    return {
        "main_lifts": ["squat", "bench", "deadlift", "ohp"],
        "supplemental": [
            "squat_variation",
            "hinge_variation",
            "bench_variation",
            "press_variation"
        ],
        "accessory": [
            "single_leg_knee_dominant",
            "single_leg_hip_dominant",
            "posterior_chain",
            "upper_pull_vertical",
            "upper_pull_horizontal",
            "upper_push_horizontal",
            "upper_push_vertical",
            "triceps",
            "biceps",
            "scap_stability",
            "core_anti_extension",
            "core_anti_rotation",
            "core_flexion",
            "carry"
        ],
        "conditioning": [
            "intervals_short",
            "steady_state",
            "jump_rope"
        ],
        "mobility": [
            "hip_ir_er",
            "hip_flexor",
            "adductor",
            "t_spine",
            "ankles"
        ]
    }

def publish_library(request_id):
    """Main publish logic"""
    try:
        # Get current meta
        meta = get_meta()
        current_version = int(meta.get('version', 0))
        new_version = current_version + 1
        
        # Get all exercises
        exercises = get_all_exercises()
        
        if not exercises:
            return error_response(400, 'NO_EXERCISES', 'No exercises found in library', request_id)
        
        # Build payload
        now = datetime.now(timezone.utc).isoformat()
        payload = {
            "library": "styrkr",
            "program": "531_krypteia_v1",
            "version": new_version,
            "publishedAt": now,
            "slots": get_slot_taxonomy(),
            "exercises": exercises
        }
        
        # Compute etag
        etag = compute_etag(payload)
        payload["etag"] = etag
        
        # Define S3 keys
        versioned_key = f"{CONFIG_PREFIX}exercises.v{new_version}.json"
        latest_key = f"{CONFIG_PREFIX}exercises.latest.json"
        
        # Publish to S3
        # Versioned (immutable)
        publish_to_s3(
            versioned_key,
            payload,
            "public, max-age=31536000, immutable"
        )
        
        # Latest (short cache)
        publish_to_s3(
            latest_key,
            payload,
            "public, max-age=300, stale-while-revalidate=86400"
        )
        
        # Update meta
        update_meta(new_version, etag, latest_key, versioned_key)
        
        return success_response(200, {
            "message": "Library published successfully",
            "version": new_version,
            "etag": etag,
            "exerciseCount": len(exercises),
            "publishedAt": now,
            "urls": {
                "latest": f"https://{CONFIG_BUCKET_NAME}/{latest_key}",
                "versioned": f"https://{CONFIG_BUCKET_NAME}/{versioned_key}"
            }
        })
    
    except Exception as e:
        print(f"Error in publish_library: {e}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'PUBLISH_FAILED', f'Failed to publish library: {str(e)}', request_id)

def should_debounce():
    """Check if we should skip publish due to recent activity"""
    try:
        response = config_table.get_item(
            Key={'PK': DEBOUNCE_KEY, 'SK': 'TIMESTAMP'}
        )
        
        if 'Item' in response:
            last_publish = float(response['Item'].get('timestamp', 0))
            elapsed = time.time() - last_publish
            
            if elapsed < DEBOUNCE_SECONDS:
                print(f"Debouncing: Last publish was {elapsed:.1f}s ago (threshold: {DEBOUNCE_SECONDS}s)")
                return True
        
        return False
    except Exception as e:
        print(f"Error checking debounce: {e}")
        return False

def update_debounce_timestamp():
    """Update the last publish timestamp"""
    try:
        config_table.put_item(
            Item={
                'PK': DEBOUNCE_KEY,
                'SK': 'TIMESTAMP',
                'timestamp': Decimal(str(time.time())),
                'updatedAt': datetime.now(timezone.utc).isoformat()
            }
        )
    except Exception as e:
        print(f"Error updating debounce timestamp: {e}")

def handle_stream_event(event, context):
    """Handle DynamoDB Stream event"""
    print(f"Stream event with {len(event.get('Records', []))} records")
    
    # Check if we should debounce
    if should_debounce():
        print("Skipping publish due to debounce")
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Skipped due to debounce'})
        }
    
    # Publish the library
    request_id = context.aws_request_id
    result = publish_library(request_id)
    
    # Update debounce timestamp
    update_debounce_timestamp()
    
    return result

def handle_api_event(event, context):
    """Handle API Gateway event (manual publish)"""
    request_id = context.aws_request_id
    method = event['requestContext']['http']['method']
    
    # Verify authentication
    user_context = get_user_context(event)
    print(f"User context: {json.dumps(user_context)}")
    
    if not user_context or not user_context.get('userId'):
        return error_response(403, 'FORBIDDEN', 'Invalid or missing authentication', request_id)
    
    # Only POST allowed
    if method != 'POST':
        return error_response(405, 'METHOD_NOT_ALLOWED', 'Method not allowed', request_id)
    
    # Publish the library (skip debounce for manual publish)
    result = publish_library(request_id)
    
    # Update debounce timestamp
    update_debounce_timestamp()
    
    return result

def handler(event, context):
    """Lambda handler - supports both API Gateway and DynamoDB Streams"""
    try:
        print(f"Event source: {event.get('Records', [{}])[0].get('eventSource', 'apigateway')}")
        
        # Check if this is a DynamoDB Stream event
        if 'Records' in event and event['Records']:
            first_record = event['Records'][0]
            if first_record.get('eventSource') == 'aws:dynamodb':
                return handle_stream_event(event, context)
        
        # Otherwise, treat as API Gateway event
        return handle_api_event(event, context)
    
    except Exception as e:
        print(f"Handler error: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL', f'Internal server error: {str(e)}', context.aws_request_id)

