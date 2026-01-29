package io.github.steveswinsburg.fhirstore.config;

import io.github.steveswinsburg.fhirstore.interceptors.WriteProtectionInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * HAPI FHIR 8.4 configuration - interceptors registered via YAML config.
 */
@Configuration
public class FhirServerConfiguration {

    @Bean
    public WriteProtectionInterceptor writeProtectionInterceptor() {
        return new WriteProtectionInterceptor();
    }
}