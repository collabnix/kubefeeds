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

# Check if Node.js is installed
check_nodejs() {
    print_status "Checking Node.js installation..."
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js 16+ first."
        echo "Visit: https://nodejs.org/en/download/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        print_error "Node.js version 16+ required. Current version: $(node --version)"
        exit 1
    fi
    
    print_success "Node.js $(node --version) found"
}

# Check if npm is installed
check_npm() {
    print_status "Checking npm installation..."
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed."
        exit 1
    fi
    print_success "npm $(npm --version) found"
}

# Setup project files
setup_project() {
    print_status "Setting up project files..."
    
    # Create public directory if it doesn't exist
    if [ ! -d "public" ]; then
        mkdir -p public
        print_status "Created public directory"
    fi
    
    # Ensure index.html exists
    if [ ! -f "public/index.html" ]; then
        print_warning "Frontend file missing, using existing or creating basic version"
    else
        print_success "Frontend files ready"
    fi
    
    # Check essential files
    essential_files=("app.js" "package.json")
    for file in "${essential_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "$file not found. Please ensure all files are present."
            exit 1
        fi
    done
    
    print_success "Project files verified"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Please ensure all files are in the correct location."
        exit 1
    fi
    
    npm install
    print_success "Dependencies installed"
}

# Check if port is available
check_port() {
    PORT=${1:-3000}
    print_status "Checking if port $PORT is available..."
    
    if command -v lsof &> /dev/null && lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null; then
        print_warning "Port $PORT is already in use"
        print_status "Trying to stop any existing KubeFeeds processes..."
        
        # Try to stop existing processes
        pkill -f "node.*app.js" 2>/dev/null || true
        sleep 2
        
        if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null; then
            print_error "Port $PORT is still in use. Please stop the existing service or use a different port."
            return 1
        fi
    fi
    
    print_success "Port $PORT is available"
}

# Start application
start_application() {
    print_status "Starting KubeFeeds application..."
    
    # Check port availability
    check_port 3000 || exit 1
    
    print_status "Starting application in background..."
    nohup npm start > kubefeeds.log 2>&1 &
    APP_PID=$!
    echo $APP_PID > kubefeeds.pid
    
    print_status "Application started with PID: $APP_PID"
    print_status "Waiting for application to initialize..."
    
    # Wait for application to start
    MAX_ATTEMPTS=20
    ATTEMPT=1
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if curl -s http://localhost:3000/api/stats > /dev/null 2>&1; then
            print_success "? KubeFeeds is running and responding!"
            break
        fi
        
        if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            print_error "? Application failed to start after $MAX_ATTEMPTS attempts"
            print_status "Check logs: tail -f kubefeeds.log"
            return 1
        fi
        
        echo -n "."
        sleep 2
        ATTEMPT=$((ATTEMPT + 1))
    done
    
    echo ""
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Test API endpoints
    if curl -s http://localhost:3000/api/stats > /dev/null; then
        print_success "? API endpoints are working"
    else
        print_warning "?? API endpoints not responding yet"
    fi
    
    # Test main page
    if curl -s http://localhost:3000/ | grep -i "kubefeeds" > /dev/null 2>&1; then
        print_success "? Main page is working"
    else
        print_warning "?? Main page not responding properly yet"
    fi
}

# Main deployment process
main() {
    echo
    print_status "Starting KubeFeeds deployment process..."
    echo
    
    check_nodejs
    check_npm
    setup_project
    install_dependencies
    start_application
    verify_deployment
    
    echo
    print_success "? KubeFeeds deployment completed!"
    echo
    echo "????????????????????????????????????????????????????????????????????????????"
    echo "? Access your portal: http://localhost:3000"
    echo "? API endpoint: http://localhost:3000/api/stats"
    echo "? Logs: tail -f kubefeeds.log"
    echo "? Stop: ./start.sh stop"
    echo "? Restart: ./start.sh restart"
    echo "? Status: ./start.sh status"
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
        if [ -f kubefeeds.pid ]; then
            PID=$(cat kubefeeds.pid)
            kill $PID 2>/dev/null || true
            rm -f kubefeeds.pid
            print_success "KubeFeeds stopped"
        else
            pkill -f "node.*app.js" 2>/dev/null || true
            print_success "KubeFeeds processes stopped"
        fi
        ;;
    "restart")
        print_status "Restarting KubeFeeds..."
        $0 stop
        sleep 3
        $0
        ;;
    "status")
        print_status "Checking KubeFeeds status..."
        if curl -s http://localhost:3000/api/stats > /dev/null 2>&1; then
            print_success "? KubeFeeds is running"
            echo "? Stats: $(curl -s http://localhost:3000/api/stats)"
        else
            print_error "? KubeFeeds is not responding"
            if [ -f kubefeeds.pid ]; then
                print_status "PID file exists: $(cat kubefeeds.pid)"
            fi
        fi
        ;;
    "logs")
        if [ -f kubefeeds.log ]; then
            tail -f kubefeeds.log
        else
            print_error "Log file not found"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "KubeFeeds Quick Start Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no command)  Start KubeFeeds"
        echo "  stop          Stop KubeFeeds"
        echo "  restart       Restart KubeFeeds"
        echo "  status        Check if KubeFeeds is running"
        echo "  logs          View application logs"
        echo "  help          Show this help message"
        ;;
    *)
        main
        ;;
esac