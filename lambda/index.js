const { EC2Client, StartInstancesCommand, waitUntilInstanceRunning } = require("@aws-sdk/client-ec2");
const { GlobalAcceleratorClient, UpdateEndpointGroupCommand } = require("@aws-sdk/client-global-accelerator");
const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

const ec2 = new EC2Client({ region: "us-east-1" });
const ga = new GlobalAcceleratorClient({ region: "us-west-2" });
const sns = new SNSClient({ region: "ca-central-1" });

const INSTANCE_ID = process.env.SECONDARY_INSTANCE_ID;
const ENDPOINT_GROUP_ARN = process.env.ENDPOINT_GROUP_ARN;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;
const SECONDARY_ELASTIC_IP = process.env.SECONDARY_ELASTIC_IP;

exports.handler = async (event) => {
  try {
    console.log(`🟢 Starting instance ${INSTANCE_ID}...`);
    await ec2.send(new StartInstancesCommand({ InstanceIds: [INSTANCE_ID] }));

    console.log("⏳ Waiting for instance to enter 'running' state...");
    await waitUntilInstanceRunning(
      { client: ec2, maxWaitTime: 60 },
      { InstanceIds: [INSTANCE_ID] }
    );
    console.log("✅ Instance is running.");

    console.log("🔁 Updating Global Accelerator endpoint weight...");
    await ga.send(new UpdateEndpointGroupCommand({
      EndpointGroupArn: ENDPOINT_GROUP_ARN,
      EndpointConfigurations: [
        {
          EndpointId: INSTANCE_ID,
          Weight: 100
        }
      ]
    }));
    console.log("✅ Global Accelerator weight updated.");

    await sns.send(new PublishCommand({
      TopicArn: SNS_TOPIC_ARN,
      Subject: "🔥 DR Failover Executed",
      Message: `Failover triggered. Instance ${INSTANCE_ID} is now active.`,
    }));
    console.log("📨 SNS notification sent.");

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Success" }),
    };

  } catch (err) {
    console.error("❌ Error during failover:", err);

    try {
      await sns.send(new PublishCommand({
        TopicArn: SNS_TOPIC_ARN,
        Subject: "❗ DR Failover Failed",
        Message: `Error: ${err.message || JSON.stringify(err)}`,
      }));
      console.log("📨 Failure alert sent.");
    } catch (snsErr) {
      console.error("❌ Failed to send failure alert:", snsErr);
    }

    throw err;
  }
};