import type { APIGatewayProxyEventV2, APIGatewayProxyResultV2, Context } from "aws-lambda";

export const handler = async (
  event: APIGatewayProxyEventV2,
  context: Context
): Promise<APIGatewayProxyResultV2> => {
  console.log("Hello world lambda invoked", { requestId: context.awsRequestId, event });

  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: "Hello World",
      requestId: context.awsRequestId,
      timestamp: new Date().toISOString(),
    }),
  };
};

