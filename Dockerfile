FROM hapiproject/hapi:latest

# Copy our custom interceptors jar to the extra-classes directory (this is where HAPI looks for custom classes)
COPY target/fhirstore-customisations-*.jar /app/extra-classes/

# Copy our custom configuration
COPY conf/hapi.application.yaml /app/config/application.yaml