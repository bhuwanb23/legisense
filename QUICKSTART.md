# Legisense Quick Start Guide

Get your Legisense application running in minutes with Docker!

## Prerequisites

- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Git

## Quick Start (5 minutes)

### 1. Clone and Setup
```bash
git clone <your-repository-url>
cd legisense
cp env.example .env
```

### 2. Start Development Environment
```bash
# On Windows
scripts\docker-dev.bat start

# On Linux/Mac
./scripts/docker-dev.sh start
```

### 3. Access Your Application
- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:8000/api/
- **Admin Panel**: http://localhost:8000/admin/

### 4. Create Admin User
```bash
# On Windows
scripts\docker-dev.bat superuser

# On Linux/Mac
./scripts/docker-dev.sh superuser
```

## Production Deployment

### 1. Configure Environment
```bash
# Edit production settings
nano .env
# Set DEBUG=false, secure SECRET_KEY, and API keys
```

### 2. Start Production
```bash
# On Windows
scripts\docker-prod.bat start

# On Linux/Mac
./scripts/docker-prod.sh start
```

### 3. Access Production
- **Application**: http://localhost:3000
- **API**: http://localhost:8000/api/

## Common Commands

### Development
```bash
# View logs
scripts\docker-dev.bat logs

# Run migrations
scripts\docker-dev.bat migrate

# Stop services
scripts\docker-dev.bat stop

# Clean up
scripts\docker-dev.bat cleanup
```

### Production
```bash
# Monitor services
scripts\docker-prod.bat monitor

# Backup database
scripts\docker-prod.bat backup

# Scale services
scripts\docker-prod.bat scale 3 2
```

## Troubleshooting

### Port Already in Use
```bash
# Check what's using the port
netstat -ano | findstr :8080
netstat -ano | findstr :8000

# Kill the process or change ports in docker-compose files
```

### Services Not Starting
```bash
# Check logs
scripts\docker-dev.bat logs

# Restart services
scripts\docker-dev.bat restart
```

### Database Issues
```bash
# Reset database
scripts\docker-dev.bat cleanup
scripts\docker-dev.bat start
```

## Next Steps

1. **Configure AI APIs**: Add your OpenRouter API key to `.env`
2. **Customize Settings**: Modify `legisense_backend/settings.py`
3. **Add Features**: Develop new features in the Flutter app
4. **Deploy**: Use the production scripts for deployment

## Need Help?

- Check the full [DOCKER.md](DOCKER.md) documentation
- Review service logs: `scripts\docker-dev.bat logs`
- Check service status: `scripts\docker-dev.bat status`

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter Web   │    │  Django Backend │    │   PostgreSQL    │
│   (Frontend)    │◄──►│   (API Server)  │◄──►│   (Database)    │
│   Port: 8080    │    │   Port: 8000    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │     Redis       │
                       │   (Cache)       │
                       │   Port: 6379    │
                       └─────────────────┘
```

Happy coding! 🚀
