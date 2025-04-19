const AWS = require('aws-sdk');

const ec2 = new AWS.EC2();
const ga = new AWS.GlobalAccelerator();
const sns = new AWS.SNS();

const INSTANCE_ID = process.env.SECONDARY_INSTANCE_ID;
const ENDPOINT_GROUP_ARN = process.env.ENDPOINT_GROUP_ARN;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;

exports.handler = async (event) => {
  console.log("🚨 Failover Lambda Triggered");
  console.log("🌐 Environment Vars:", {
    INSTANCE_ID,
    ENDPOINT_GROUP_ARN,
    SNS_TOPIC_ARN,
  });

  try {
    // 1. Start the secondary instance
    console.log(`🟢 Starting EC2 instance: ${INSTANCE_ID}`);
    await ec2.startInstances({ InstanceIds: [INSTANCE_ID] }).promise();

    // 2. Wait for it to become running
    console.log(`⏳ Waiting for instance to enter 'running' state...`);
    await ec2.waitFor('instanceRunning', { InstanceIds: [INSTANCE_ID] }).promise();
    console.log(`✅ Instance is now running.`);

    // 3. Update GA endpoint weight
    console.log(`🔁 Updating Global Accelerator endpoint weight...`);
    await ga.updateEndpointGroup({
      EndpointGroupArn: ENDPOINT_GROUP_ARN,
      EndpointConfigurations: [
        {
          EndpointId: INSTANCE_ID,
          Weight: 128, // Full traffic
        },
      ],
    }).promise();
    console.log(`✅ Global Accelerator weight updated.`);

    // 4. Send success notification
    const message = `Failover triggered. Instance ${INSTANCE_ID} is now active.`;
    await sns.publish({
      TopicArn: SNS_TOPIC_ARN,
      Subject: "🔥 DR Failover Executed",
      Message: message,
    }).promise();
    console.log(`📨 SNS notification sent.`);

    return {
      statusCode: 200,
      body: JSON.stringify({ status: "Success", message }),
    };

  } catch (err) {
    console.error("❌ Failover Error:", err);

    // Optional: notify on failure too
    try {
      await sns.publish({
        TopicArn: SNS_TOPIC_ARN,
        Subject: "❗ DR Failover Failed",
        Message: `Error: ${err.message || JSON.stringify(err)}`,
      }).promise();
      console.log("📨 Failure notification sent.");
    } catch (snsErr) {
      console.error("❌ Failed to send SNS failure alert:", snsErr);
    }

    throw err; // Let CloudWatch log the error
  }
};