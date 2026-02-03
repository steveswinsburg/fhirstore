# 🔥 FHIRStore - FHIR Server
> A containerised HAPI FHIR server running on PostgreSQL

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![HAPI FHIR](https://img.shields.io/badge/HAPI%20FHIR-Latest-green?logo=fire)](https://hapifhir.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue?logo=postgresql)](https://www.postgresql.org/)

## 🚀 Quick Start

Get your FHIR server running in seconds:

```bash
# Build customisations (if any)
./build.sh

# Start
docker compose up -d

# Check status
docker compose ps
```

**🎉 That's it!** Your FHIR server is now running at `http://localhost`

## 📋 What's Inside

| Service | Description | Port | Health Check |
|---------|-------------|------|--------------|
| **NGINX** | Reverse Proxy | `80` | `http://localhost` |
| **HAPI FHIR** | FHIR R4 Server | `8080` | Internal only |
| **PostgreSQL** | Database Backend | `5432` | Internal only |

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     NGINX       │───▶│   HAPI FHIR     │───▶│   PostgreSQL    │
│  Reverse Proxy  │    │   Server        │    │   Database      │
│   Port: 80      │    │   Port: 8080    │    │   Port: 5432    │
│  (External)     │    │  (Internal)     │    │  (Internal)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                │              ┌─────────────────┐
                                └─────────────▶│   DB Schema     │
                                               │   fhir_data     │
                                               │   fhir_app_user │
                                               └─────────────────┘
```

## 🔧 Customisations

This project supports custom FHIR interceptors and configurations to extend the server functionality.

### Structure
```
src/main/java/io/github/steveswinsburg/fhirstore/
├── interceptors/               # FHIR interceptors
└── ...                         # Other customisations
```

### Adding New Interceptors

1. Create your interceptor class in `src/main/java/io/github/steveswinsburg/fhirstore/interceptors/`:

```java
@Component
@Interceptor
public class MyInterceptor {
    @Hook(Pointcut.SERVER_INCOMING_REQUEST_PRE_HANDLED)
    public void intercept(RequestDetails requestDetails) {
        // Your logic here
    }
}
```

2. Build and restart:
```bash
./build.sh
docker-compose restart fhir
```

The HAPI FHIR server automatically discovers interceptors via Spring's component scanning.

### Build Process

The `./build.sh` script:
1. Compiles the Java customisations into a JAR (`target/fhirstore-customisations-1.0.0.jar`)
2. Builds a custom Docker image extending the official HAPI FHIR image
3. Copies the JAR and configuration into the container

## 🛠️ Configuration

### Database Setup
- **User**: `fhir_app_user` (application user)
- **Schema**: `fhir_data` (dedicated FHIR schema)
- **Admin**: `admin` (database administration)

The user and schema are initialized on startup.

### FHIR Configuration
Custom application settings are in `hapi.application.yaml`.

## ⚙️ Environment Variables

The project uses a `.env` file to configure sensitive settings and provides them to docker-compose. Copy the provided `.env` file and modify as needed:

### Admin Credentials
```bash
FHIR_ADMIN_USERNAME=admin
FHIR_ADMIN_PASSWORD=admin123
```

These credentials are required to be provided via Basic Auth for all write requests.

### Database Settings
```bash
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin
POSTGRES_DB=hapi
```

## 🔐 SSL Configuration

The project includes automated SSL certificate generation using Let's Encrypt for production deployments.

### Quick SSL Setup

1. **Edit SSL configuration**:
   ```bash
   # Edit conf/ssl.conf with your settings
   DOMAIN=fhir.yourdomain.com
   EMAIL=admin@yourdomain.com
   STAGING=false
   AUTO_REDIRECT=true
   AUTO_RELOAD=true
   ```

2. **Run SSL setup**:
   ```bash
   ./ssl-setup.sh
   ```

### SSL Configuration Options

| Setting | Description | Example |
|---------|-------------|---------|
| `DOMAIN` | Your domain name (required) | `fhir.example.com` |
| `EMAIL` | Let's Encrypt account email | `admin@example.com` |
| `STAGING` | Use staging certificates for testing | `false` |
| `AUTO_REDIRECT` | Redirect HTTP to HTTPS | `true` |
| `AUTO_RELOAD` | Auto-reload nginx after setup | `true` |

### Prerequisites

- Domain must point to your server (DNS A record)
- Ports 80 and 443 must be accessible from internet
- Services should be running *before* SSL setup

### Manual SSL Commands

```bash
# Test with staging certificates first
echo "STAGING=true" >> conf/ssl.conf
./ssl-setup.sh

# Switch to production certificates  
echo "STAGING=false" >> conf/ssl.conf
./ssl-setup.sh

# Check certificate status
docker compose exec certbot certbot certificates
```

## 🔧 Commands

### Development
```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Database Access
```bash
# Connect to PostgreSQL
docker compose exec db psql -U admin -d hapi

# Check FHIR schema
docker compose exec db psql -U fhir_app_user -d hapi -c "\dt fhir_data.*"
```

### Troubleshooting
```bash
# Check container status
docker compose ps

# Restart specific service
docker compose restart fhir

# Fresh start (removes data)
docker compose down -v
docker compose up -d
```

## 🌐 API Examples

### Get Server Metadata
```bash
curl http://localhost/fhir/metadata
```

### Create a Patient
```bash
curl -X POST http://localhost/fhir/Patient \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "name": [{"family": "Doe", "given": ["John"]}],
    "gender": "male"
  }'
```

### Create a Patient (with ID)
```bash
curl -X PUT http://localhost/fhir/Patient/abc1234 \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "abc1234",
    "name": [{"family": "Doe", "given": ["John"]}],
    "gender": "male"
  }'
```

### Search Patients
```bash
curl "http://localhost/fhir/Patient?family=Doe"
```

## 📈 Scaling

### Horizontal Scaling
```bash
# Multiple FHIR instances
docker compose up --scale fhir=3
```

## 📜 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

**Made with ❤️ for the FHIR community**
