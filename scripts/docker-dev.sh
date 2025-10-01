#!/bin/bash

# Legisense Docker Development Script
# This script helps manage the development environment

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

# Function to start development environment
start_dev() {
    print_status "Starting Legisense development environment..."
    check_docker
    check_docker_compose
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from template..."
        cp env.example .env
        print_warning "Please edit .env file with your configuration before continuing."
    fi
    
    # Start services
    docker-compose -f docker-compose.dev.yml up --build -d
    
    print_success "Development environment started!"
    print_status "Frontend: http://localhost:8080"
    print_status "Backend: http://localhost:8000"
    print_status "Database: localhost:5432"
    print_status "Redis: localhost:6379"
}

# Function to stop development environment
stop_dev() {
    print_status "Stopping Legisense development environment..."
    docker-compose -f docker-compose.dev.yml down
    print_success "Development environment stopped!"
}

# Function to restart development environment
restart_dev() {
    print_status "Restarting Legisense development environment..."
    stop_dev
    start_dev
}

# Function to view logs
view_logs() {
    local service=${1:-""}
    if [ -n "$service" ]; then
        print_status "Viewing logs for $service..."
        docker-compose -f docker-compose.dev.yml logs -f "$service"
    else
        print_status "Viewing logs for all services..."
        docker-compose -f docker-compose.dev.yml logs -f
    fi
}

# Function to run database migrations
run_migrations() {
    print_status "Running database migrations..."
    docker-compose -f docker-compose.dev.yml exec backend python manage.py migrate
    print_success "Database migrations completed!"
}

# Function to create superuser
create_superuser() {
    print_status "Creating Django superuser..."
    docker-compose -f docker-compose.dev.yml exec backend python manage.py createsuperuser
    print_success "Superuser created!"
}

# Function to collect static files
collect_static() {
    print_status "Collecting static files..."
    docker-compose -f docker-compose.dev.yml exec backend python manage.py collectstatic --noinput
    print_success "Static files collected!"
}

# Function to run tests
run_tests() {
    local service=${1:-"backend"}
    if [ "$service" = "backend" ]; then
        print_status "Running backend tests..."
        docker-compose -f docker-compose.dev.yml exec backend python manage.py test
    elif [ "$service" = "frontend" ]; then
        print_status "Running frontend tests..."
        docker-compose -f docker-compose.dev.yml exec frontend flutter test
    else
        print_error "Invalid service. Use 'backend' or 'frontend'"
        exit 1
    fi
    print_success "Tests completed!"
}

# Function to clean up
cleanup() {
    print_status "Cleaning up Docker resources..."
    docker-compose -f docker-compose.dev.yml down -v
    docker system prune -f
    print_success "Cleanup completed!"
}

# Function to show status
show_status() {
    print_status "Legisense Development Environment Status:"
    echo ""
    docker-compose -f docker-compose.dev.yml ps
    echo ""
    print_status "Service URLs:"
    print_status "  Frontend: http://localhost:8080"
    print_status "  Backend: http://localhost:8000"
    print_status "  Database: localhost:5432"
    print_status "  Redis: localhost:6379"
}

# Function to show help
show_help() {
    echo "Legisense Docker Development Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start the development environment"
    echo "  stop        Stop the development environment"
    echo "  restart     Restart the development environment"
    echo "  logs        View logs (optionally specify service: backend, frontend, db, redis)"
    echo "  migrate     Run database migrations"
    echo "  superuser   Create Django superuser"
    echo "  static      Collect static files"
    echo "  test        Run tests (specify service: backend, frontend)"
    echo "  status      Show environment status"
    echo "  cleanup     Clean up Docker resources"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs backend"
    echo "  $0 test frontend"
    echo "  $0 migrate"
}

# Main script logic
case "${1:-help}" in
    start)
        start_dev
        ;;
    stop)
        stop_dev
        ;;
    restart)
        restart_dev
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
    test)
        run_tests "$2"
        ;;
    status)
        show_status
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
