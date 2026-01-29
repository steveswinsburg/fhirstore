package io.github.steveswinsburg.fhirstore.interceptors;

import ca.uhn.fhir.interceptor.api.Hook;
import ca.uhn.fhir.interceptor.api.Interceptor;
import ca.uhn.fhir.interceptor.api.Pointcut;
import ca.uhn.fhir.rest.api.RestOperationTypeEnum;
import ca.uhn.fhir.rest.api.server.RequestDetails;
import ca.uhn.fhir.rest.server.exceptions.ForbiddenOperationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Interceptor that protects write operations (CREATE, UPDATE, DELETE, PATCH) unless proper basic auth is provided
 * 
 * Can be enabled/disabled via configuration
 */
@Component
@Interceptor
public class WriteProtectionInterceptor {

    private static final Logger logger = LoggerFactory.getLogger(WriteProtectionInterceptor.class);

    @Value("${fhirstore.write-protection.enabled:true}")
    private boolean enabled;
    
    @Value("${fhirstore.write-protection.auth-username}")
    private String authUsername;
    
    @Value("${fhirstore.write-protection.auth-password}")
    private String authPassword;

    public WriteProtectionInterceptor() {
        logger.info("WriteProtectionInterceptor initialized. Enabled: {}", enabled);
    }

    @Hook(Pointcut.SERVER_INCOMING_REQUEST_PRE_HANDLED)
    public void interceptIncomingRequest(RequestDetails theRequestDetails) {
        if (!enabled) {
            logger.debug("Write protection is disabled, allowing all operations");
            return;
        }

        RestOperationTypeEnum operation = theRequestDetails.getRestOperationType();
        
        // Check if this is a write operation we want to protect
        if (isProtectedOperation(operation)) {
            logger.info("Intercepted {} operation on {}", operation, theRequestDetails.getRequestPath());
            
            // Check for basic auth
            String authHeader = theRequestDetails.getHeader("Authorization");
            if (authHeader != null && isValidBasicAuth(authHeader)) {
                logger.info("Valid basic auth provided, allowing {} operation", operation);
                return;
            }
            
            logger.warn("Blocking {} operation - no valid authentication provided", operation);
            throw new ForbiddenOperationException(
                String.format("%s operations are disabled. Please provide valid basic authentication.", operation.name())
            );
        }
    }

    private boolean isProtectedOperation(RestOperationTypeEnum operation) {
        // If write protection is enabled, protect all write operations
        switch (operation) {
            case CREATE:
            case UPDATE:
            case DELETE:
            case PATCH:
                return true;
            default:
                return false;
        }
    }

    private boolean isValidBasicAuth(String authHeader) {
        if (!authHeader.startsWith("Basic ")) {
            return false;
        }
        
        try {
            String encodedCredentials = authHeader.substring(6);
            String credentials = new String(Base64.getDecoder().decode(encodedCredentials), StandardCharsets.UTF_8);
            String[] parts = credentials.split(":", 2);
            
            if (parts.length != 2) {
                return false;
            }
            
            String username = parts[0];
            String password = parts[1];
            
            boolean isValid = authUsername.equals(username) && authPassword.equals(password);
            
            if (!isValid) {
                logger.warn("Invalid credentials provided: username={}", username);
            }
            
            return isValid;
        } catch (Exception e) {
            logger.error("Error parsing basic auth header", e);
            return false;
        }
    }
}