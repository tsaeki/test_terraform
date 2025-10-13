# ActiveMQ Pub/Sub Testing Guide

This guide shows how to test ActiveMQ messaging with the Java application.

## Prerequisites

- ActiveMQ is running in the same ECS task (accessible at localhost:61616)
- Java application is deployed with ActiveMQ dependencies

## Testing Queue (Point-to-Point) Messaging

### 1. Send a message to a queue

```bash
curl -X POST http://localhost:8080/activemq/send/queue/test.queue \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Queue!"}'
```

Expected response:
```json
{
  "status": "success",
  "queue": "test.queue",
  "message": "Hello from Queue!",
  "timestamp": "1697155200000"
}
```

### 2. Receive the message from the queue

```bash
curl http://localhost:8080/activemq/receive/queue/test.queue
```

Expected response:
```json
{
  "status": "success",
  "queue": "test.queue",
  "message": "Hello from Queue!",
  "timestamp": "1697155200000"
}
```

## Testing Topic (Pub/Sub) Messaging

The application has a listener subscribed to `test.topic` that will automatically receive and store messages.

### 1. Publish a message to a topic

```bash
curl -X POST http://localhost:8080/activemq/send/topic/test.topic \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Topic!"}'
```

Expected response:
```json
{
  "status": "success",
  "topic": "test.topic",
  "message": "Hello from Topic!",
  "timestamp": "1697155200000"
}
```

### 2. Check received topic messages

The subscriber automatically receives messages. Check what was received:

```bash
curl http://localhost:8080/activemq/received
```

Expected response:
```json
{
  "count": 1,
  "messages": ["Hello from Topic!"]
}
```

### 3. Clear received messages

```bash
curl -X DELETE http://localhost:8080/activemq/received
```

## Testing from Outside ECS (Using ALB)

If your Java application is accessible via an Application Load Balancer, replace `localhost:8080` with your ALB DNS name:

```bash
curl -X POST http://your-alb-dns-name/activemq/send/queue/test.queue \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from outside!"}'
```

## Verify in ActiveMQ Web Console

1. Access the ActiveMQ Web Console at http://localhost:8161/admin (if port forwarded)
2. Navigate to "Queues" or "Topics"
3. You should see `test.queue` and `test.topic` listed
4. View the number of messages pending, enqueued, and dequeued

## Testing Scenarios

### Scenario 1: Queue with Multiple Messages

```bash
# Send 5 messages
for i in {1..5}; do
  curl -X POST http://localhost:8080/activemq/send/queue/test.queue \
    -H "Content-Type: application/json" \
    -d "{\"message\": \"Message $i\"}"
done

# Receive them one by one
for i in {1..5}; do
  curl http://localhost:8080/activemq/receive/queue/test.queue
done
```

### Scenario 2: Topic with Multiple Subscribers

The application has one built-in subscriber to `test.topic`. To test multiple subscribers:

1. Publish several messages:
```bash
for i in {1..3}; do
  curl -X POST http://localhost:8080/activemq/send/topic/test.topic \
    -H "Content-Type: application/json" \
    -d "{\"message\": \"Topic message $i\"}"
done
```

2. Check received messages:
```bash
curl http://localhost:8080/activemq/received
```

## Troubleshooting

### Connection Refused
- Ensure ActiveMQ is running: Check ECS console for container status
- Verify ActiveMQ is listening on port 61616
- Check application logs: `docker logs <container-id>`

### No Messages Received
- Check queue/topic names match exactly
- Verify messages were sent successfully (check response status)
- For topics, ensure the listener was running BEFORE messages were published
- Check ActiveMQ Web Console to see if messages are in the queue/topic

### Application Fails to Start
- Check that ActiveMQ dependency is in pom.xml
- Verify application.properties has correct broker URL
- Check ECS task logs for connection errors

## Clean Up

To remove all received messages from the in-memory store:
```bash
curl -X DELETE http://localhost:8080/activemq/received
```

Note: This only clears the in-memory list. Messages in ActiveMQ queues persist until consumed.
