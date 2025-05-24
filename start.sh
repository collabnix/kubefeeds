#!/bin/bash

echo "? Starting KubeFeeds Portal"
echo "============================"

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed!"
    echo "Please install Node.js from: https://nodejs.org"
    exit 1
fi

print_success "Node.js $(node --version) found"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed!"
    exit 1
fi

print_success "npm $(npm --version) found"

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found!"
    print_status "Please run this script from the kubefeeds directory"
    exit 1
fi

# Create public directory if it doesn't exist
if [ ! -d "public" ]; then
    print_status "Creating public directory..."
    mkdir -p public
fi

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    print_status "Installing dependencies..."
    npm install
    print_success "Dependencies installed"
else
    print_success "Dependencies already installed"
fi

# Kill any existing process on port 3000
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "Port 3000 is in use. Stopping existing processes..."
    pkill -f "node.*app.js" || true
    sleep 2
fi

# Start the application
print_status "Starting KubeFeeds application..."
print_status "This may take a moment to initialize..."

# Start in background and capture PID
npm start &
APP_PID=$!
echo $APP_PID > kubefeeds.pid

print_success "KubeFeeds started with PID: $APP_PID"

# Wait for the application to start
print_status "Waiting for application to initialize..."
sleep 5

# Check if the application is running
MAX_ATTEMPTS=10
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_success "? KubeFeeds portal is now running!"
        break
    fi
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        print_error "? Application failed to start properly"
        print_status "Check the logs with: tail -f kubefeeds.log"
        exit 1
    fi
    
    echo -n "."
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

echo ""
echo "? SUCCESS! Your KubeFeeds portal is ready!"
echo ""
echo "????????????????????????????????????????????????????????????????"
echo "? Access your portal: http://localhost:3000"
echo "? API endpoint: http://localhost:3000/api/stats"  
echo "? View articles: http://localhost:3000/api/articles"
echo "? View logs: tail -f kubefeeds.log"
echo "? Stop server: kill $(cat kubefeeds.pid)"
echo "????????????????????????????????????????????????????????????????"
echo ""
print_status "? The portal will automatically start collecting Kubernetes feeds!"
print_status "? Articles will appear as they are processed (may take a few minutes)"
echo ""
print_success "? Open your browser and visit: http://localhost:3000"