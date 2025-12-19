def get_user_id(event: dict) -> str | None:
    try:
        jwt = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {})
        claims = jwt.get('claims', {})
        return claims.get('sub')
    except (KeyError, AttributeError):
        return None

def get_user_context(event: dict) -> dict | None:
    try:
        jwt = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {})
        claims = jwt.get('claims', {})
        return {
            'userId': claims.get('sub'),
            'email': claims.get('email'),
            'name': claims.get('given_name', '') + ' ' + claims.get('family_name', ''),
            'provider': claims.get('cognito:username', '').split('_')[0] if 'cognito:username' in claims else 'unknown'
        }
    except (KeyError, AttributeError):
        return None

