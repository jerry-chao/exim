#!/bin/bash

# Kafka topics to be created
TOPICS=(
    "exim-auth"
    "exim-auth-response"
)

# Default configuration
PARTITIONS=1
REPLICATION_FACTOR=1
BOOTSTRAP_SERVER="kafka:9092"
KAFKA_CONTAINER="kafka"

# Create topics
for topic in "${TOPICS[@]}"; do
    echo "Creating topic: $topic"
    docker exec $KAFKA_CONTAINER /opt/bitnami/kafka/bin/kafka-topics.sh \
        --create \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --topic "$topic" \
        --partitions $PARTITIONS \
        --replication-factor $REPLICATION_FACTOR

    if [ $? -eq 0 ]; then
        echo "Successfully created topic: $topic"
    else
        echo "Failed to create topic: $topic"
    fi
done

# List all topics to verify
echo "Listing all topics:"
docker exec $KAFKA_CONTAINER /opt/bitnami/kafka/bin/kafka-topics.sh \
    --list \
    --bootstrap-server $BOOTSTRAP_SERVER