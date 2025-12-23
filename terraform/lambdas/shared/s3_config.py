import json
import os
import time
import boto3
from typing import Optional, Dict, Any

s3_client = boto3.client('s3')

# In-memory cache with TTL
_cache: Dict[str, Dict[str, Any]] = {}
CACHE_TTL = 600  # 10 minutes

def get_app_config(key: str) -> Dict[str, Any]:
    """
    Fetch configuration from S3 with in-memory caching and ETag support.
    
    Args:
        key: The S3 key (e.g., 'exercises.latest.json', 'plan.template.json')
    
    Returns:
        Parsed JSON configuration
    """
    bucket = os.environ.get('CONFIG_BUCKET')
    if not bucket:
        raise ValueError('CONFIG_BUCKET environment variable not set')
    
    now = time.time()
    
    # Check cache
    if key in _cache:
        cached = _cache[key]
        if now - cached['timestamp'] < CACHE_TTL:
            # Cache still valid
            return cached['data']
        
        # Cache expired, try conditional fetch with ETag
        etag = cached.get('etag')
        if etag:
            try:
                response = s3_client.get_object(
                    Bucket=bucket,
                    Key=key,
                    IfNoneMatch=etag
                )
                # New version available
                data = json.loads(response['Body'].read().decode('utf-8'))
                _cache[key] = {
                    'data': data,
                    'etag': response.get('ETag'),
                    'timestamp': now
                }
                return data
            except s3_client.exceptions.ClientError as e:
                if e.response['Error']['Code'] == '304':
                    # Not modified, refresh timestamp
                    cached['timestamp'] = now
                    return cached['data']
                raise
    
    # No cache or conditional fetch failed, do full fetch
    response = s3_client.get_object(Bucket=bucket, Key=key)
    data = json.loads(response['Body'].read().decode('utf-8'))
    
    _cache[key] = {
        'data': data,
        'etag': response.get('ETag'),
        'timestamp': now
    }
    
    return data

def clear_cache(key: Optional[str] = None):
    """Clear cache for a specific key or all keys."""
    if key:
        _cache.pop(key, None)
    else:
        _cache.clear()

