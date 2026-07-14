# Legisense Docker Setup

This document provides comprehensive instructions for running the Legisense application using Docker.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd legisense
```

### 2. Environment Setup
```bash
# Copy the example environment file
cp env.example .env

# Edit the environment variables
nano .env
```

### 3. Run the Application

#### Development Mode
```bash
# Start all services in development mode
docker-compose -f docker-compose.dev.yml up --build

# Or run in background
docker-compose -f docker-compose.dev.yml up -d --build
```

#### Production Mode
```bash
# Start all services in production mode
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

### 4. Access the Application

- **Frontend**: http://localhost:3000 (production) or http://localhost:8080 (development)
- **Backend API**: http://localhost:8000/api/
- **Database**: localhost:5432
- **Redis**: localhost:6379

## Services Overview

### Frontend (Flutter Web)
- **Container**: `legisense_frontend`
- **Port**: 3000 (production) / 8080 (development)
- **Technology**: Flutter Web with Nginx
- **Features**: Hot reload in development mode

### Backend (Django)
- **Container**: `legisense_backend`
- **Port**: 8000
- **Technology**: Django with Gunicorn
- **Features**: AI document analysis, PDF processing, simulation

### Database (PostgreSQL)
- **Container**: `legisense_db`
- **Port**: 5432
- **Database**: `legisense`
- **User**: `legisense`
- **Password**: `legisense_password`

### Cache (Redis)
- **Container**: `legisense_redis`
- **Port**: 6379
- **Purpose**: Session storage and caching

### Reverse Proxy (Nginx) - Production Only
- **Container**: `legisense_nginx`
- **Port**: 80 (HTTP) / 443 (HTTPS)
- **Purpose**: Load balancing and SSL termination

## Environment Variables

### Required Variables
```bash
# Database
DATABASE_URL=postgresql://legisense:legisense_password@db:5432/legisense

# Django
SECRET_KEY=your-super-secret-key-change-in-production
DEBUG=false

# AI APIs
OPENROUTER_API_KEY=your-openrouter-api-key
OPENROUTER_MODEL=openai/gpt-4o-mini
```

### Optional Variables
```bash
# Redis
REDIS_URL=redis://:legisense_redis_password@redis:6379/0

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Additional AI APIs
GOOGLE_GEMINI_API_KEY=your-google-gemini-api-key
OLLAMA_BASE_URL=http://ollama:11434
```

## Development Workflow

### 1. Start Development Environment
```bash
docker-compose -f docker-compose.dev.yml up --build
```

### 2. Run Database Migrations
```bash
# Access backend container
docker-compose -f docker-compose.dev.yml exec backend bash

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser
```

### 3. Hot Reload
- **Frontend**: Changes to Flutter code will automatically reload
- **Backend**: Changes to Python code will automatically reload

### 4. View Logs
```bash
# All services
docker-compose -f docker-compose.dev.yml logs -f

# Specific service
docker-compose -f docker-compose.dev.yml logs -f backend
```

## Production Deployment

### 1. SSL Certificate Setup
```bash
# Create SSL directory
mkdir -p nginx/ssl

# Generate self-signed certificate (for testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/key.pem \
    -out nginx/ssl/cert.pem

# For production, use Let's Encrypt or your CA
```

### 2. Production Build
```bash
# Build and start production services
docker-compose up --build -d

# Run migrations
docker-compose exec backend python manage.py migrate

# Collect static files
docker-compose exec backend python manage.py collectstatic --noinput
```

### 3. Scale Services
```bash
# Scale backend workers
docker-compose up --scale backend=3

# Scale with load balancer
docker-compose --profile production up -d
```

## Database Management

### Backup Database
```bash
# Create backup
docker-compose exec db pg_dump -U legisense legisense > backup.sql

# Restore backup
docker-compose exec -T db psql -U legisense legisense < backup.sql
```

### Reset Database
```bash
# Stop services
docker-compose down

# Remove database volume
docker volume rm legisense_postgres_data

# Start services
docker-compose up --build
```

## Monitoring and Debugging

### Health Checks
```bash
# Check service health
docker-compose ps

# View health check logs
docker-compose logs backend | grep health
```

### Debugging
```bash
# Access container shell
docker-compose exec backend bash
docker-compose exec frontend sh

# View container logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Performance Monitoring
```bash
# Container resource usage
docker stats

# Service logs with timestamps
docker-compose logs -f -t
```

## Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
lsof -i :3000
lsof -i :8000

# Kill the process or change ports in docker-compose.yml
```

#### 2. Database Connection Issues
```bash
# Check database logs
docker-compose logs db

# Test database connection
docker-compose exec backend python manage.py dbshell
```

#### 3. Frontend Build Issues
```bash
# Clear Flutter cache
docker-compose exec frontend flutter clean

# Rebuild frontend
docker-compose build --no-cache frontend
```

#### 4. Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Rebuild containers
docker-compose build --no-cache
```

### Log Analysis
```bash
# Filter error logs
docker-compose logs | grep -i error

# Follow specific service logs
docker-compose logs -f backend | grep -i "ERROR\|WARNING"

# Export logs to file
docker-compose logs > application.log
```

## Security Considerations

### 1. Environment Variables
- Never commit `.env` files to version control
- Use strong, unique passwords for production
- Rotate API keys regularly

### 2. Network Security
- Use Docker networks for service isolation
- Implement proper firewall rules
- Use HTTPS in production

### 3. Container Security
- Run containers as non-root users
- Keep base images updated
- Scan images for vulnerabilities

## Performance Optimization

### 1. Resource Limits
```yaml
# Add to docker-compose.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
```

### 2. Caching
- Enable Redis caching
- Use CDN for static assets
- Implement browser caching

### 3. Database Optimization
- Use connection pooling
- Optimize database queries
- Implement read replicas for scaling

## Backup and Recovery

### 1. Automated Backups
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec -T db pg_dump -U legisense legisense > "backup_$DATE.sql"
```

### 2. Disaster Recovery
```bash
# Restore from backup
docker-compose down
docker volume rm legisense_postgres_data
docker-compose up -d db
docker-compose exec -T db psql -U legisense legisense < backup_20240101_120000.sql
```

## Contributing

### 1. Development Setup
```bash
# Fork and clone repository
git clone <your-fork-url>
cd legisense

# Create feature branch
git checkout -b feature/your-feature

# Start development environment
docker-compose -f docker-compose.dev.yml up --build
```

### 2. Testing
```bash
# Run backend tests
docker-compose exec backend python manage.py test

# Run frontend tests
docker-compose exec frontend flutter test
```

### 3. Code Quality
```bash
# Backend linting
docker-compose exec backend flake8 .

# Frontend linting
docker-compose exec frontend flutter analyze
```

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Docker and service logs
3. Create an issue in the repository
4. Contact the development team

## License

This project is licensed under the MIT License - see the LICENSE file for details.
