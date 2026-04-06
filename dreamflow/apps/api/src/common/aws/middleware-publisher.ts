import { randomUUID } from 'node:crypto';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { PublishCommand, SNSClient } from '@aws-sdk/client-sns';
import { SendMessageCommand, SQSClient } from '@aws-sdk/client-sqs';

const awsRegion = process.env.AWS_REGION || 'ap-southeast-2';

const sqsQueueUrl = process.env.AWS_SQS_MIDDLEWARE_QUEUE_URL?.trim() || '';
const snsTopicArn = process.env.AWS_SNS_NOTIFICATIONS_TOPIC_ARN?.trim() || '';
const s3Bucket = process.env.AWS_S3_MIDDLEWARE_BUCKET?.trim() || '';

const sqsClient = sqsQueueUrl ? new SQSClient({ region: awsRegion }) : null;
const snsClient = snsTopicArn ? new SNSClient({ region: awsRegion }) : null;
const s3Client = s3Bucket ? new S3Client({ region: awsRegion }) : null;

type MiddlewareEventType = 'presence.location.ingested' | 'alerts.created';

interface PublishMiddlewareEventInput {
  eventType: MiddlewareEventType;
  payload: Record<string, unknown>;
}

interface PublishAlertInput {
  alertId: string;
  circleId: string;
  userId: string;
  type: string;
  message: string;
  createdAt: string;
}

export async function publishMiddlewareEvent(input: PublishMiddlewareEventInput): Promise<void> {
  if (!sqsClient || !sqsQueueUrl) {
    return;
  }

  await sqsClient.send(
    new SendMessageCommand({
      QueueUrl: sqsQueueUrl,
      MessageGroupId: undefined,
      MessageDeduplicationId: undefined,
      MessageBody: JSON.stringify({
        id: randomUUID(),
        eventType: input.eventType,
        occurredAt: new Date().toISOString(),
        payload: input.payload
      })
    })
  );
}

export async function publishAlertNotification(input: PublishAlertInput): Promise<void> {
  if (!snsClient || !snsTopicArn) {
    return;
  }

  await snsClient.send(
    new PublishCommand({
      TopicArn: snsTopicArn,
      Subject: `DreamFlow alert: ${input.type}`,
      Message: JSON.stringify({
        id: randomUUID(),
        eventType: 'alerts.created',
        occurredAt: input.createdAt,
        payload: input
      })
    })
  );
}

export async function archiveMiddlewareArtifact(
  keyPrefix: string,
  body: Record<string, unknown>
): Promise<void> {
  if (!s3Client || !s3Bucket) {
    return;
  }

  const key = `${keyPrefix}/${Date.now()}-${randomUUID()}.json`;
  await s3Client.send(
    new PutObjectCommand({
      Bucket: s3Bucket,
      Key: key,
      Body: JSON.stringify(body),
      ContentType: 'application/json'
    })
  );
}
