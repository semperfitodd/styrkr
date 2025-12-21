import type { APIGatewayProxyResultV2 } from "aws-lambda";
import type { ErrorResponse } from "./types.js";

/**
 * Create a standardized error response
 */
export function errorResponse(
  statusCode: number,
  code: string,
  message: string,
  requestId: string
): APIGatewayProxyResultV2 {
  const response: ErrorResponse = {
    error: {
      code,
      message,
      requestId,
    },
  };
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(response),
  };
}

/**
 * Create a standardized success response
 */
export function successResponse(statusCode: number, data: any): APIGatewayProxyResultV2 {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  };
}



