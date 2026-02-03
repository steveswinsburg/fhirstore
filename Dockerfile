FROM hapiproject/hapi:latest

# Copy our custom interceptors jar to the extra-classes directory
COPY target/fhirstore-customisations-*.jar /app/extra-classes/

# Copy our custom configuration
COPY conf/hapi.application.yaml /app/config/application.yaml

# Copy keystore for SSL (configured via environment variables)
COPY conf/keystore.jks /app/keystore.jks