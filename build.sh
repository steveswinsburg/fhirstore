#!/bin/bash

# Build script for our customisations
echo "Building customisations..."

# Detect container tool (docker or podman)
if command -v docker &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v podman &> /dev/null && podman compose --help &> /dev/null; then
    COMPOSE_CMD="podman compose"
else
    echo "❌ Neither docker nor podman found. Please install docker or podman."
    exit 1
fi

echo "Using container tool: $COMPOSE_CMD"

# Build the jar
mvn clean package -DskipTests

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "JAR created: target/fhirstore-customisations-*.jar"
    echo ""
    echo "Building Docker image..."
    $COMPOSE_CMD build fhir --no-cache
    echo ""
    echo "To startup, you can now run:"
    echo "  $COMPOSE_CMD up -d"
    echo ""
else
    echo "Build failed!"
    exit 1
fi