#!/bin/bash

# KubeFeeds Quick Start Script
# This script helps you get KubeFeeds running quickly

set -e

echo "? KubeFeeds Quick Start"
echo "======================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker found: $(docker --version)"
        return 0
    else
        print_error "Docker not found. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        return 1
    fi
}

# Check if Docker Compose is available
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose found: $(docker-compose --version)"
        return 0
    elif docker compose version &> /dev/null; then
        print_success "Docker Compose found: $(docker compose version)"
        return 0
    else
        print_warning "Docker Compose not found, using docker run instead"
        return 1
    fi
}

# Start with Docker Compose
start_with_compose() {
    print_status "Starting KubeFeeds with Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi
    
    print_success "KubeFeeds started with Docker Compose!"
}

# Start with Docker run
start_with_docker() {
    print_status "Starting KubeFeeds with Docker..."
    
    # Stop existing container if running
    docker stop kubefeeds 2>/dev/null || true
    docker rm kubefeeds 2>/dev/null || true
    
    # Run the container
    docker run -d \
        --name kubefeeds \
        -p 3000:3000 \
        -v kubefeeds-data:/app/data \
        --restart unless-stopped \
        collabnix/kubefeeds:latest
    
    print_success "KubeFeeds started with Docker!"
}

# Check if container is healthy
check_health() {
    print_status "Checking application health..."
    
    # Wait a moment for the app to start
    sleep 10
    
    if curl -s http://localhost:3000/api/stats > /dev/null; then
        print_success "? KubeFeeds is running and healthy!"
        print_status "? Visit: http://localhost:3000"
        print_status "? API: http://localhost:3000/api/stats"
        return 0
    else
        print_error "? Application doesn't seem to be responding"
        print_status "Check logs with: docker logs kubefeeds"
        return 1
    fi
}

# Main function
main() {
    echo
    print_status "KubeFeeds - Kubernetes News Aggregator"
    print_status "Repository: https://github.com/collabnix/kubefeeds"
    echo
    
    # Check prerequisites
    if ! check_docker; then
        exit 1
    fi
    
    # Choose deployment method
    if check_docker_compose && [ -f "docker-compose.yml" ]; then
        start_with_compose
    else
        start_with_docker
    fi
    
    # Health check
    check_health
    
    echo
    print_success "? KubeFeeds is now running!"
    echo
    echo "????????????????????????????????????????????????????????????????????????????"
    echo "? Access your portal: http://localhost:3000"
    echo "? API endpoint: http://localhost:3000/api/stats"
    echo "? Stop: docker stop kubefeeds"
    echo "? Logs: docker logs -f kubefeeds"
    echo "? Refresh feeds: curl -X POST http://localhost:3000/api/refresh"
    echo "????????????????????????????????????????????????????????????????????????????"
    echo
    print_status "The application will automatically start fetching Kubernetes feeds!"
    print_status "It may take a few minutes for the first articles to appear."
    echo
}

# Handle script arguments
case "${1:-}" in
    "stop")
        print_status "Stopping KubeFeeds..."
        docker stop kubefeeds 2>/dev/null || true
        if [ -f "docker-compose.yml" ]; then
            if command -v docker-compose &> /dev/null; then
                docker-compose down
            else
                docker compose down
            fi
        fi
        print_success "KubeFeeds stopped"
        ;;
    "logs")
        docker logs -f kubefeeds
        ;;
    "restart")
        print_status "Restarting KubeFeeds..."
        docker restart kubefeeds
        print_success "KubeFeeds restarted"
        ;;
    "status")
        if curl -s http://localhost:3000/api/stats > /dev/null; then
            print_success "KubeFeeds is running"
        else
            print_error "KubeFeeds is not responding"
        fi
        ;;
    "update")
        print_status "Updating KubeFeeds..."
        docker pull collabnix/kubefeeds:latest
        docker stop kubefeeds 2>/dev/null || true
        docker rm kubefeeds 2>/dev/null || true
        start_with_docker
        check_health
        ;;
    *)
        main
        ;;
esac