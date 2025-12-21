import type { 
  APIGatewayProxyEventV2WithJWTAuthorizer, 
  APIGatewayProxyResultV2, 
  Context 
} from "aws-lambda";
import { GetCommand, PutCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, DATA_TABLE } from "../shared/dynamodb.js";
import { getUserId } from "../shared/auth.js";
import { errorResponse, successResponse } from "../shared/response.js";
import { validateStrength, calculateTrainingMaxes } from "../shared/validation.js";
import type { Strength } from "../shared/types.js";

/**
 * GET /strength - Retrieve user strength data
 */
async function getStrength(userId: string, requestId: string): Promise<APIGatewayProxyResultV2> {
  try {
    const result = await docClient.send(
      new GetCommand({
        TableName: DATA_TABLE,
        Key: {
          PK: `USER#${userId}`,
          SK: "STRENGTH",
        },
      })
    );

    if (!result.Item) {
      return errorResponse(404, "NOT_FOUND", "Strength data not found", requestId);
    }

    const { PK, SK, ...strength } = result.Item;
    return successResponse(200, strength);
  } catch (error) {
    console.error("Error getting strength:", error);
    return errorResponse(500, "INTERNAL", "Internal server error", requestId);
  }
}

/**
 * PUT /strength - Create or update user strength data
 */
async function putStrength(
  userId: string,
  body: any,
  requestId: string
): Promise<APIGatewayProxyResultV2> {
  try {
    const validation = validateStrength(body);
    if (!validation.valid) {
      return errorResponse(400, "VALIDATION_ERROR", validation.error!, requestId);
    }

    const now = new Date().toISOString();
    
    // Check if strength exists to preserve createdAt
    const existing = await docClient.send(
      new GetCommand({
        TableName: DATA_TABLE,
        Key: {
          PK: `USER#${userId}`,
          SK: "STRENGTH",
        },
      })
    );

    const trainingMaxes = calculateTrainingMaxes(body.oneRepMaxes, body.tmPolicy);

    const strength: Strength & { PK: string; SK: string } = {
      PK: `USER#${userId}`,
      SK: "STRENGTH",
      oneRepMaxes: body.oneRepMaxes,
      tmPolicy: body.tmPolicy,
      trainingMaxes,
      createdAt: existing.Item?.createdAt || now,
      updatedAt: now,
    };

    await docClient.send(
      new PutCommand({
        TableName: DATA_TABLE,
        Item: strength,
      })
    );

    const { PK, SK, ...responseStrength } = strength;
    return successResponse(200, responseStrength);
  } catch (error) {
    console.error("Error putting strength:", error);
    return errorResponse(500, "INTERNAL", "Internal server error", requestId);
  }
}

/**
 * Main handler
 */
export const handler = async (
  event: APIGatewayProxyEventV2WithJWTAuthorizer,
  context: Context
): Promise<APIGatewayProxyResultV2> => {
  console.log("Strength handler invoked", {
    requestId: context.awsRequestId,
    method: event.requestContext.http.method,
    path: event.requestContext.http.path,
  });

  const requestId = context.awsRequestId;
  const method = event.requestContext.http.method;

  // Extract userId from JWT
  const userId = getUserId(event);
  if (!userId) {
    return errorResponse(403, "FORBIDDEN", "Invalid or missing authentication", requestId);
  }

  try {
    if (method === "GET") {
      return await getStrength(userId, requestId);
    }

    if (method === "PUT") {
      const body = event.body ? JSON.parse(event.body) : {};
      return await putStrength(userId, body, requestId);
    }

    return errorResponse(405, "METHOD_NOT_ALLOWED", "Method not allowed", requestId);
  } catch (error) {
    console.error("Unhandled error:", error);
    return errorResponse(500, "INTERNAL", "Internal server error", requestId);
  }
};



