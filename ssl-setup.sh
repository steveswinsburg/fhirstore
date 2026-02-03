#!/bin/bash

# SSL Setup Script for FHIR Server
# This script obtains SSL certificates from Let's Encrypt using the conf/ssl.conf config file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="conf/ssl.conf"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file '$CONFIG_FILE' not found!${NC}"
    echo -e "${YELLOW}Please create $CONFIG_FILE with your SSL settings.${NC}"
    echo -e "${BLUE}Example configuration:${NC}"
    cat << EOF
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com
AGREE_TOS=true
STAGING=false
ENABLE_HSTS=true
HSTS_MAX_AGE=31536000
AUTO_REDIRECT=true
AUTO_RELOAD=true
EOF
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# Validate required settings
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo -e "${RED}Error: DOMAIN and EMAIL must be set in $CONFIG_FILE${NC}"
    exit 1
fi

if [ "$DOMAIN" = "localhost" ]; then
    echo -e "${YELLOW}Warning: Domain is set to 'localhost'${NC}"
    echo -e "${YELLOW}This will not work for Let's Encrypt certificates.${NC}"
    echo -e "${YELLOW}Please update DOMAIN in $CONFIG_FILE to your actual domain.${NC}"
    read -p "Continue anyway for local testing? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${BLUE}SSL Configuration:${NC}"
echo -e "  Domain: $DOMAIN"
echo -e "  Email: $EMAIL"
echo -e "  Staging: $STAGING"
echo -e "  HSTS: $ENABLE_HSTS"
echo -e "  Auto-redirect: $AUTO_REDIRECT"
echo ""

# Set staging flag if enabled
STAGING_FLAG=""
if [ "$STAGING" = "true" ]; then
    STAGING_FLAG="--staging"
    echo -e "${YELLOW}Using Let's Encrypt staging environment (test certificates)${NC}"
fi

# Update nginx configuration with the real domain
echo -e "${YELLOW}Updating nginx configuration...${NC}"
sed -i.bak "s/server_name localhost;/server_name $DOMAIN;/g" conf/nginx.conf
sed -i.bak "s|/etc/letsencrypt/live/localhost/|/etc/letsencrypt/live/$DOMAIN/|g" conf/nginx.conf

# Start services without SSL first (for initial certificate request)
echo -e "${YELLOW}Starting services for initial setup...${NC}"
docker compose up -d

# Wait for nginx to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Request initial certificate
echo -e "${YELLOW}Requesting SSL certificate from Let's Encrypt...${NC}"
docker compose exec certbot certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    $STAGING_FLAG \
    -d $DOMAIN

# Test certificate renewal
echo -e "${YELLOW}Testing certificate renewal...${NC}"
docker compose exec certbot certbot renew --dry-run

# Update nginx configuration for HTTPS
if [ "$AUTO_REDIRECT" = "true" ] && [ "$DOMAIN" != "localhost" ]; then
    echo -e "${YELLOW}Enabling HTTPS configuration...${NC}"
    
    # Enable HTTPS server block and redirect
    sed -i.bak 's/# server {/server {/g' conf/nginx.conf
    sed -i.bak 's/# }/}/g' conf/nginx.conf
    sed -i.bak 's/#     /    /g' conf/nginx.conf
    sed -i.bak 's/#}/}/g' conf/nginx.conf
    
    # Enable redirect by commenting out direct proxy and enabling redirect
    sed -i.bak '/# Uncomment below to redirect to HTTPS after SSL setup/,/# }/{ 
        s/# location \/ {/location \/ {/g; 
        s/#     return 301/    return 301/g; 
        s/# }/}/g;
    }' conf/nginx.conf
    
    # Comment out the HTTP proxy location
    sed -i.bak '/# For testing, serve HTTP directly/,/^    }$/{{
        /location \/ {/,/^    }$/{{
            s/^/    # /g
        }}
    }}' conf/nginx.conf
fi

# Reload nginx to use the new certificates
if [ "$AUTO_RELOAD" = "true" ]; then
    echo -e "${YELLOW}Reloading nginx with SSL certificates...${NC}"
    docker compose restart nginx
fi

echo -e "${GREEN}SSL setup complete!${NC}"
if [ "$DOMAIN" != "localhost" ]; then
    echo -e "${GREEN}Your FHIR server is now available at: https://$DOMAIN${NC}"
else
    echo -e "${YELLOW}Local testing setup complete at: http://$DOMAIN${NC}"
fi
echo -e "${YELLOW}Certificates will auto-renew every 12 hours.${NC}"

# Display certificate info
if [ "$DOMAIN" != "localhost" ]; then
    echo -e "${YELLOW}Certificate information:${NC}"
    docker compose exec certbot certbot certificates
fi