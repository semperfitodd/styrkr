import type { 
  APIGatewayProxyEventV2WithJWTAuthorizer, 
  APIGatewayProxyResultV2, 
  Context 
} from "aws-lambda";
import { GetCommand, PutCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, DATA_TABLE } from "../shared/dynamodb.js";
import { getUserId } from "../shared/auth.js";
import { errorResponse, successResponse } from "../shared/response.js";
import { validateProfile } from "../shared/validation.js";
import type { Profile } from "../shared/types.js";

/**
 * GET /profile - Retrieve user profile
 */
async function getProfile(userId: string, requestId: string): Promise<APIGatewayProxyResultV2> {
  try {
    const result = await docClient.send(
      new GetCommand({
        TableName: DATA_TABLE,
        Key: {
          PK: `USER#${userId}`,
          SK: "PROFILE",
        },
      })
    );

    if (!result.Item) {
      return errorResponse(404, "NOT_FOUND", "Profile not found", requestId);
    }

    const { PK, SK, ...profile } = result.Item;
    return successResponse(200, profile);
  } catch (error) {
    console.error("Error getting profile:", error);
    return errorResponse(500, "INTERNAL", "Internal server error", requestId);
  }
}

/**
 * PUT /profile - Create or update user profile
 */
async function putProfile(
  userId: string,
  body: any,
  requestId: string
): Promise<APIGatewayProxyResultV2> {
  try {
    const validation = validateProfile(body);
    if (!validation.valid) {
      return errorResponse(400, "VALIDATION_ERROR", validation.error!, requestId);
    }

    const now = new Date().toISOString();
    
    // Check if profile exists to preserve createdAt
    const existing = await docClient.send(
      new GetCommand({
        TableName: DATA_TABLE,
        Key: {
          PK: `USER#${userId}`,
          SK: "PROFILE",
        },
      })
    );

    const profile: Profile & { PK: string; SK: string } = {
      PK: `USER#${userId}`,
      SK: "PROFILE",
      // A) Training Schedule
      trainingDaysPerWeek: body.trainingDaysPerWeek,
      preferredStartDay: body.preferredStartDay,
      preferredUnits: body.preferredUnits,
      // B) Non-Lifting Days
      nonLiftingDaysEnabled: body.nonLiftingDaysEnabled,
      nonLiftingDayMode: body.nonLiftingDayMode,
      conditioningLevel: body.conditioningLevel,
      // C) Movement Capabilities
      movementCapabilities: body.movementCapabilities,
      // D) Movement Constraints
      constraints: body.constraints,
      // Metadata
      createdAt: existing.Item?.createdAt || now,
      updatedAt: now,
    };

    await docClient.send(
      new PutCommand({
        TableName: DATA_TABLE,
        Item: profile,
      })
    );

    const { PK, SK, ...responseProfile } = profile;
    return successResponse(200, responseProfile);
  } catch (error) {
    console.error("Error putting profile:", error);
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
  console.log("Profile handler invoked", {
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
      return await getProfile(userId, requestId);
    }

    if (method === "PUT") {
      const body = event.body ? JSON.parse(event.body) : {};
      return await putProfile(userId, body, requestId);
    }

    return errorResponse(405, "METHOD_NOT_ALLOWED", "Method not allowed", requestId);
  } catch (error) {
    console.error("Unhandled error:", error);
    return errorResponse(500, "INTERNAL", "Internal server error", requestId);
  }
};


