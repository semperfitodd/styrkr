from typing import Dict, Optional

def extract_user_id(event: dict) -> Optional[str]:
    """
    Extract userId (sub claim) from API Gateway JWT authorizer context.
    
    Args:
        event: Lambda event from API Gateway
    
    Returns:
        User ID (sub claim) or None if not found
    """
    try:
        claims = event['requestContext']['authorizer']['jwt']['claims']
        return claims.get('sub')
    except (KeyError, TypeError):
        return None

def validate_user_context(event: dict) -> Dict[str, str]:
    """
    Validate and extract user context from JWT claims.
    Raises ValueError if required claims are missing.
    
    Args:
        event: Lambda event from API Gateway
    
    Returns:
        Dict with userId, email, and name
    
    Raises:
        ValueError: If required claims are missing
    """
    try:
        claims = event['requestContext']['authorizer']['jwt']['claims']
        
        user_id = claims.get('sub')
        email = claims.get('email')
        
        if not user_id:
            raise ValueError('Missing sub claim in JWT')
        
        if not email:
            raise ValueError('Missing email claim in JWT')
        
        # Extract name from given_name and family_name
        given_name = claims.get('given_name', '')
        family_name = claims.get('family_name', '')
        name = f"{given_name} {family_name}".strip() or email
        
        return {
            'userId': user_id,
            'email': email,
            'name': name
        }
    except (KeyError, TypeError) as e:
        raise ValueError(f'Invalid JWT context: {str(e)}')

def get_dynamodb_user_key(user_id: str) -> str:
    """
    Generate DynamoDB partition key for user data.
    
    Args:
        user_id: User ID (sub claim from JWT)
    
    Returns:
        Partition key in format USER#{userId}
    """
    return f"USER#{user_id}"

