#!/bin/bash

# Build script for our customisations
echo "Building customisations..."

# Build the jar
mvn clean package -DskipTests

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "JAR created: target/fhirstore-customisations-*.jar"
    echo ""
    echo "Building Docker image..."
    docker compose build fhir --no-cache
    echo ""
    echo "To startup, you can now run:"
    echo "  docker compose up -d"
    echo ""
else
    echo "Build failed!"
    exit 1
fi