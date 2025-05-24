# KubeFeeds - Kubernetes News Aggregator

[![CI/CD](https://github.com/collabnix/kubefeeds/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/collabnix/kubefeeds/actions/workflows/ci-cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **A comprehensive portal that aggregates Kubernetes-related content from various RSS feeds and displays article abstracts in a beautiful, responsive interface.**

## Features

- ? **Automated Feed Aggregation**: Fetches from 8+ popular Kubernetes blogs and news sources
- ? **Smart Content Filtering**: Only shows Kubernetes-related content using intelligent keyword detection
- ? **Abstract Generation**: Creates concise, readable summaries of articles
- ? **Real-time Search**: Search through all collected articles instantly
- ? **Responsive Design**: Perfect experience on desktop, tablet, and mobile
- ? **Statistics Dashboard**: Monitor total articles, sources, and daily updates
- ? **Performance Optimized**: Fast loading with pagination and caching
- ? **RESTful API**: Full API access for integration with other tools
- ? **Docker Ready**: Easy deployment with Docker and Kubernetes
- ? **Automated Updates**: GitHub Actions keep feeds updated automatically

## Live Demo

Visit the portal locally after setup: **http://localhost:3000**


## ? Quick Start

### Option 1: One-Line Setup

```bash
curl -sSL https://raw.githubusercontent.com/collabnix/kubefeeds/main/start.sh | bash
```

### Option 2: Manual Setup

```bash
# Clone the repository
git clone https://github.com/collabnix/kubefeeds.git
cd kubefeeds

# Install dependencies
npm install

# Start the application
npm start

# Visit http://localhost:3000
```

### Option 3: Docker

```bash
# Using existing image (when available)
docker run -d -p 3000:3000 --name kubefeeds collabnix/kubefeeds:latest

# Or build locally
docker build -t kubefeeds .
docker run -d -p 3000:3000 --name kubefeeds kubefeeds
```

### Option 4: Docker Compose

```bash
docker-compose up -d
```

## ? Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Server port |
| `NODE_ENV` | `development` | Environment mode |

### Adding New RSS Sources

Use the API to add new feeds:

```bash
curl -X POST http://localhost:3000/api/feeds \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Kubernetes Blog",
    "url": "https://example.com/feed.xml"
  }'
```

## ? API Reference

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/articles` | Get paginated articles |
| `GET` | `/api/articles/:id` | Get specific article |
| `GET` | `/api/feeds` | List all RSS sources |
| `POST` | `/api/feeds` | Add new RSS source |
| `POST` | `/api/refresh` | Manually refresh feeds |
| `GET` | `/api/stats` | Get portal statistics |

### Example API Usage

```javascript
// Fetch latest articles
const response = await fetch('/api/articles?page=1&limit=10');
const { articles, totalPages } = await response.json();

// Search articles
const searchResponse = await fetch('/api/articles?search=helm&page=1');
const searchResults = await searchResponse.json();

// Get statistics
const statsResponse = await fetch('/api/stats');
const stats = await statsResponse.json();
console.log(`Total articles: ${stats.total_articles}`);
```

## ? Automated Updates

The portal automatically stays updated through:

### GitHub Actions Workflow

- ? **Scheduled Updates**: Runs every 6 hours
- ? **Feed Refresh**: Automatically fetches new content
- ?? **CI/CD Pipeline**: Tests and validates changes
- ? **Docker Images**: Multi-architecture builds

### Manual Refresh

You can manually trigger updates:

```bash
# Via API
curl -X POST http://localhost:3000/api/refresh

# Via script
./start.sh restart

# Via GitHub Actions
# Go to Actions tab ? "Run workflow"
```

## ?? Development

### Project Structure

```
kubefeeds/
??? app.js                 # Main server application
??? package.json           # Dependencies and scripts
??? Dockerfile            # Container configuration
??? public/
?   ??? index.html        # Frontend web application
??? .github/
?   ??? workflows/
?       ??? ci-cd.yml     # GitHub Actions workflow
??? start.sh              # Quick deployment script
??? TROUBLESHOOTING.md    # Troubleshooting guide
??? README.md             # This file
```

### Local Development

```bash
# Install dependencies
npm install

# Start in development mode
npm run dev  # or npm start

# View logs
tail -f kubefeeds.log

# Stop application
./start.sh stop
```

### Available Scripts

```bash
./start.sh          # Start the application
./start.sh stop     # Stop the application  
./start.sh restart  # Restart the application
./start.sh status   # Check if running
./start.sh logs     # View logs
./start.sh help     # Show help
```

## ? Docker Deployment

### Build and Run

```bash
# Build image
docker build -t kubefeeds .

# Run container
docker run -d \
  --name kubefeeds \
  -p 3000:3000 \
  -v kubefeeds-data:/app/data \
  --restart unless-stopped \
  kubefeeds

# Check logs
docker logs -f kubefeeds

# Stop and remove
docker stop kubefeeds && docker rm kubefeeds
```

### Docker Compose

```yaml
version: '3.8'
services:
  kubefeeds:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - kubefeeds-data:/app/data
    restart: unless-stopped
    environment:
      - NODE_ENV=production

volumes:
  kubefeeds-data:
```

## ? Production Deployment

### Cloud Platforms

#### Vercel (Recommended)
1. Fork this repository
2. Connect to Vercel
3. Deploy automatically

#### DigitalOcean App Platform
1. Create new app from GitHub
2. Use these settings:
   - **Build Command**: `npm install`
   - **Run Command**: `npm start`

#### Docker-based (AWS, Azure, GCP)
```bash
docker pull collabnix/kubefeeds:latest
# Deploy using your platform's container service
```

### Traditional VPS/Server

```bash
# Clone and setup
git clone https://github.com/collabnix/kubefeeds.git
cd kubefeeds

# Make executable
chmod +x start.sh

# Install and start
./start.sh

# Setup as service (optional)
sudo cp kubefeeds.service /etc/systemd/system/
sudo systemctl enable kubefeeds
sudo systemctl start kubefeeds
```

## ? Monitoring

### Health Checks

```bash
# Check application status
curl http://localhost:3000/api/stats

# Test all endpoints
curl http://localhost:3000/api/articles
curl http://localhost:3000/api/feeds
curl http://localhost:3000/
```

### Logs

```bash
# Application logs
./start.sh logs

# Or directly
tail -f kubefeeds.log

# Docker logs
docker logs -f kubefeeds
```

## ? Security

- ? **Input Validation**: All API inputs are validated
- ? **SQL Injection Prevention**: Parameterized queries
- ? **XSS Protection**: Content sanitization
- ? **CORS Protection**: Configurable cross-origin policies

## ? Troubleshooting

Having issues? Check our [Troubleshooting Guide](TROUBLESHOOTING.md) for common solutions.

### Quick Fixes

```bash
# Port already in use
./start.sh stop
./start.sh start

# Dependencies issues
rm -rf node_modules package-lock.json
npm install

# Database issues
rm kubefeeds.db
npm start  # Will recreate database
```

## ? Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly: `npm start`
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

## ? License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ? Acknowledgments

- **Kubernetes Community** for the amazing ecosystem
- **RSS Feed Providers** for sharing valuable content
- **Open Source Contributors** who make projects like this possible

## ? Roadmap

- [ ] ? **AI-Powered Summaries**: Enhanced abstract generation
- [ ] ? **Mobile App**: Native iOS/Android applications  
- [ ] ? **Push Notifications**: Real-time alerts for important updates
- [ ] ? **Themes**: Customizable UI themes
- [ ] ? **Analytics**: Detailed usage statistics
- [ ] ? **Multi-language**: Support for multiple languages

---

**Made with ?? by the [Collabnix](https://collabnix.com) community**

? **Star this repository if you find it useful!**

## ? Links

- **Repository**: https://github.com/collabnix/kubefeeds
- **Issues**: https://github.com/collabnix/kubefeeds/issues
- **Discussions**: https://github.com/collabnix/kubefeeds/discussions
- **Collabnix Community**: https://collabnix.com
