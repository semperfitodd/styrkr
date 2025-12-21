import type { 
  APIGatewayProxyEventV2WithJWTAuthorizer, 
  APIGatewayProxyResultV2, 
  Context 
} from "aws-lambda";
import { successResponse } from "../shared/response.js";

export const handler = async (
  event: APIGatewayProxyEventV2WithJWTAuthorizer,
  context: Context
): Promise<APIGatewayProxyResultV2> => {
  return successResponse(200, {
    message: "Hello from Styrkr API",
    requestId: context.awsRequestId,
    timestamp: new Date().toISOString(),
  });
};



