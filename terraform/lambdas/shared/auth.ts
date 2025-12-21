import type { APIGatewayProxyEventV2WithJWTAuthorizer } from "aws-lambda";

/**
 * Extract userId from JWT claims in API Gateway event
 * @param event API Gateway event with JWT authorizer
 * @returns userId (Cognito sub) or null if not found
 */
export function getUserId(event: APIGatewayProxyEventV2WithJWTAuthorizer): string | null {
  const jwt = event.requestContext.authorizer?.jwt;
  if (!jwt || !jwt.claims || !jwt.claims.sub) {
    return null;
  }
  return jwt.claims.sub as string;
}



