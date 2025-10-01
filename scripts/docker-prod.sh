#!/bin/bash

# Legisense Docker Production Script
# This script helps manage the production environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose is not installed. Please install it and try again."
        exit 1
    fi
}

# Function to check environment file
check_env() {
    if [ ! -f .env ]; then
        print_error ".env file not found. Please create it from env.example and configure it for production."
        exit 1
    fi
    
    # Check for critical production variables
    if ! grep -q "SECRET_KEY=" .env || grep -q "your-super-secret-key" .env; then
        print_error "Please set a secure SECRET_KEY in your .env file"
        exit 1
    fi
    
    if ! grep -q "DEBUG=false" .env; then
        print_warning "DEBUG should be set to false in production"
    fi
}

# Function to start production environment
start_prod() {
    print_status "Starting Legisense production environment..."
    check_docker
    check_docker_compose
    check_env
    
    # Start services
    docker-compose up --build -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Run migrations
    print_status "Running database migrations..."
    docker-compose exec backend python manage.py migrate
    
    # Collect static files
    print_status "Collecting static files..."
    docker-compose exec backend python manage.py collectstatic --noinput
    
    print_success "Production environment started!"
    print_status "Frontend: http://localhost:3000"
    print_status "Backend: http://localhost:8000"
    print_status "Database: localhost:5432"
    print_status "Redis: localhost:6379"
}

# Function to stop production environment
stop_prod() {
    print_status "Stopping Legisense production environment..."
    docker-compose down
    print_success "Production environment stopped!"
}

# Function to restart production environment
restart_prod() {
    print_status "Restarting Legisense production environment..."
    stop_prod
    start_prod
}

# Function to start with Nginx
start_prod_nginx() {
    print_status "Starting Legisense production environment with Nginx..."
    check_docker
    check_docker_compose
    check_env
    
    # Check for SSL certificates
    if [ ! -f nginx/ssl/cert.pem ] || [ ! -f nginx/ssl/key.pem ]; then
        print_warning "SSL certificates not found. Generating self-signed certificates..."
        mkdir -p nginx/ssl
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/key.pem \
            -out nginx/ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    fi
    
    # Start services with Nginx
    docker-compose --profile production up --build -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Run migrations
    print_status "Running database migrations..."
    docker-compose exec backend python manage.py migrate
    
    # Collect static files
    print_status "Collecting static files..."
    docker-compose exec backend python manage.py collectstatic --noinput
    
    print_success "Production environment with Nginx started!"
    print_status "Application: https://localhost"
    print_status "Backend API: https://localhost/api/"
}

# Function to view logs
view_logs() {
    local service=${1:-""}
    if [ -n "$service" ]; then
        print_status "Viewing logs for $service..."
        docker-compose logs -f "$service"
    else
        print_status "Viewing logs for all services..."
        docker-compose logs -f
    fi
}

# Function to run database migrations
run_migrations() {
    print_status "Running database migrations..."
    docker-compose exec backend python manage.py migrate
    print_success "Database migrations completed!"
}

# Function to create superuser
create_superuser() {
    print_status "Creating Django superuser..."
    docker-compose exec backend python manage.py createsuperuser
    print_success "Superuser created!"
}

# Function to collect static files
collect_static() {
    print_status "Collecting static files..."
    docker-compose exec backend python manage.py collectstatic --noinput
    print_success "Static files collected!"
}

# Function to backup database
backup_database() {
    local backup_file="backup_$(date +%Y%m%d_%H%M%S).sql"
    print_status "Creating database backup: $backup_file"
    docker-compose exec -T db pg_dump -U legisense legisense > "$backup_file"
    print_success "Database backup created: $backup_file"
}

# Function to restore database
restore_database() {
    local backup_file=${1:-""}
    if [ -z "$backup_file" ]; then
        print_error "Please specify backup file: $0 restore <backup_file>"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will replace the current database. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "Restoring database from $backup_file..."
        docker-compose exec -T db psql -U legisense legisense < "$backup_file"
        print_success "Database restored from $backup_file"
    else
        print_status "Database restore cancelled"
    fi
}

# Function to scale services
scale_services() {
    local backend_scale=${1:-1}
    local frontend_scale=${2:-1}
    
    print_status "Scaling services..."
    print_status "Backend workers: $backend_scale"
    print_status "Frontend instances: $frontend_scale"
    
    docker-compose up --scale backend="$backend_scale" --scale frontend="$frontend_scale" -d
    print_success "Services scaled successfully!"
}

# Function to show status
show_status() {
    print_status "Legisense Production Environment Status:"
    echo ""
    docker-compose ps
    echo ""
    print_status "Service URLs:"
    print_status "  Frontend: http://localhost:3000"
    print_status "  Backend: http://localhost:8000"
    print_status "  Database: localhost:5432"
    print_status "  Redis: localhost:6379"
    echo ""
    print_status "Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Function to monitor services
monitor() {
    print_status "Monitoring Legisense services (Press Ctrl+C to stop)..."
    while true; do
        clear
        show_status
        sleep 5
    done
}

# Function to update services
update() {
    print_status "Updating Legisense services..."
    
    # Pull latest images
    docker-compose pull
    
    # Rebuild and restart services
    docker-compose up --build -d
    
    # Run migrations
    run_migrations
    
    # Collect static files
    collect_static
    
    print_success "Services updated successfully!"
}

# Function to clean up
cleanup() {
    print_warning "This will remove all containers, volumes, and images. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "Cleaning up Docker resources..."
        docker-compose down -v
        docker system prune -af
        print_success "Cleanup completed!"
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to show help
show_help() {
    echo "Legisense Docker Production Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start           Start the production environment"
    echo "  start-nginx     Start with Nginx reverse proxy"
    echo "  stop            Stop the production environment"
    echo "  restart         Restart the production environment"
    echo "  logs            View logs (optionally specify service)"
    echo "  migrate         Run database migrations"
    echo "  superuser       Create Django superuser"
    echo "  static          Collect static files"
    echo "  backup          Create database backup"
    echo "  restore         Restore database from backup"
    echo "  scale           Scale services (backend_scale frontend_scale)"
    echo "  status          Show environment status"
    echo "  monitor         Monitor services in real-time"
    echo "  update          Update services to latest version"
    echo "  cleanup         Clean up Docker resources"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 start-nginx"
    echo "  $0 logs backend"
    echo "  $0 backup"
    echo "  $0 restore backup_20240101_120000.sql"
    echo "  $0 scale 3 2"
    echo "  $0 monitor"
}

# Main script logic
case "${1:-help}" in
    start)
        start_prod
        ;;
    start-nginx)
        start_prod_nginx
        ;;
    stop)
        stop_prod
        ;;
    restart)
        restart_prod
        ;;
    logs)
        view_logs "$2"
        ;;
    migrate)
        run_migrations
        ;;
    superuser)
        create_superuser
        ;;
    static)
        collect_static
        ;;
    backup)
        backup_database
        ;;
    restore)
        restore_database "$2"
        ;;
    scale)
        scale_services "$2" "$3"
        ;;
    status)
        show_status
        ;;
    monitor)
        monitor
        ;;
    update)
        update
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
