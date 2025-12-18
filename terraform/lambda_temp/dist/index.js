export const handler = async (event, context) => {
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
