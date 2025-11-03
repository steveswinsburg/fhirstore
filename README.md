# 🔥 FHIRStore - FHIR Server
> A containerized HAPI FHIR server with PostgreSQL

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![HAPI FHIR](https://img.shields.io/badge/HAPI%20FHIR-Latest-green?logo=fire)](https://hapifhir.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue?logo=postgresql)](https://www.postgresql.org/)

## 🚀 Quick Start

Get your FHIR server running in seconds:

```bash
# Clone and start
git clone https://github.com/steveswinsburg/fhirstore.git
cd fhirstore
docker compose up -d

# Check status
docker compose ps
```

**🎉 That's it!** Your FHIR server is now running at `http://localhost:8080`

## 📋 What's Inside

| Service | Description | Port | Health Check |
|---------|-------------|------|--------------|
| **HAPI FHIR** | FHIR R4 Server | `8080` | `http://localhost:8080/fhir/metadata` |
| **PostgreSQL** | Database Backend | `5432` | Internal only |

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   HAPI FHIR     │───▶│   PostgreSQL    │
│   Server        │    │   Database      │
│   Port: 8080    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘
         │                       │
         │              ┌─────────────────┐
         └─────────────▶│  Custom Schema  │
                        │   fhir_data     │
                        │   fhir_app_user │
                        └─────────────────┘
```

## 🛠️ Configuration

### Database Setup
- **User**: `fhir_app_user` (application user)
- **Schema**: `fhir_data` (dedicated FHIR schema)
- **Admin**: `admin` (database administration)

The user and schema are initialized on startup.

### FHIR Configuration
Custom application settings in `hapi.application.yaml`:
- PostgreSQL dialect optimized for HAPI
- Hibernate search disabled for performance
- Connection pooling ready

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
curl http://localhost:8080/fhir/metadata
```

### Create a Patient
```bash
curl -X POST http://localhost:8080/fhir/Patient \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "name": [{"family": "Doe", "given": ["John"]}],
    "gender": "male"
  }'
```

### Search Patients
```bash
curl "http://localhost:8080/fhir/Patient?family=Doe"
```

## 🚦 Health Checks

| Endpoint | Purpose |
|----------|---------|
| `GET /fhir/metadata` | Server capability statement |
| `GET /fhir/Patient` | Basic FHIR functionality |
| Database connection | Automatic via HAPI startup |

## 🔒 Security Notes

- Default passwords are for development only
- Change credentials in production
- Database is not exposed externally
- Consider adding authentication for production use

## 📈 Scaling

### Horizontal Scaling
```bash
# Multiple FHIR instances
docker compose up --scale fhir=3
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Made with ❤️ for the FHIR community**