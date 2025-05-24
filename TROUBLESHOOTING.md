# ? KubeFeeds Troubleshooting Guide

This guide helps you resolve common issues with KubeFeeds deployment and operation.

## ? Common Issues & Solutions

### 1. GitHub Actions Failing

#### **Issue**: Application not starting in CI
```bash
# Symptoms:
- Tests timeout
- "curl: (7) Failed to connect to localhost:3000"
- Application logs show startup errors
```

**Solutions:**
- ? **Fixed**: The new workflow includes comprehensive error handling
- ? **Fixed**: Automatic file creation if missing
- ? **Fixed**: Improved timeout and retry logic
- ? **Fixed**: Better logging and debugging information

#### **Issue**: Missing dependencies or files
```bash
# Check the workflow logs for:
- "package.json not found"
- "public/index.html missing"
- "npm ci failed"
```

**Solutions:**
- The workflow now automatically creates missing files
- Dependencies are properly cached and installed
- Project structure is validated before testing

### 2. Local Development Issues

#### **Issue**: Port 3000 already in use
```bash
Error: listen EADDRINUSE: address already in use :::3000
```

**Solutions:**
```bash
# Option 1: Stop existing processes
./start.sh stop

# Option 2: Kill all node processes
pkill -f "node.*app.js"

# Option 3: Find and kill specific process
lsof -ti:3000 | xargs kill -9

# Option 4: Use different port
PORT=3001 npm start
```

#### **Issue**: Dependencies installation fails
```bash
npm ERR! code EACCES
npm ERR! permission denied
```

**Solutions:**
```bash
# Option 1: Fix npm permissions
npm config set prefix ~/.local
export PATH=~/.local/bin:$PATH

# Option 2: Use Node Version Manager
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# Option 3: Clear npm cache
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

#### **Issue**: Application starts but shows no feeds
```bash
# Symptoms:
- API returns empty arrays
- No articles in database
- Feed sources not fetching
```

**Solutions:**
```bash
# Check RSS feed sources are accessible
curl -I https://kubernetes.io/feed.xml
curl -I https://www.cncf.io/feed/

# Manually trigger feed refresh
curl -X POST http://localhost:3000/api/refresh

# Check application logs
tail -f kubefeeds.log

# Verify database exists
ls -la kubefeeds.db
```

### 3. Docker Issues

#### **Issue**: Docker build fails
```bash
# Common error messages:
- "COPY failed: no such file or directory"
- "npm ci failed"
- "Cannot find module"
```

**Solutions:**
```bash
# Ensure all files are present
ls -la app.js package.json public/index.html

# Build with verbose output
docker build --no-cache --progress=plain -t kubefeeds .

# Check Docker build context
docker build --dry-run .
```

#### **Issue**: Container starts but not accessible
```bash
# Symptoms:
- Container running but port not accessible
- Health checks failing
- No response on localhost:3000
```

**Solutions:**
```bash
# Check container logs
docker logs kubefeeds

# Verify port mapping
docker port kubefeeds

# Test container directly
docker exec -it kubefeeds curl http://localhost:3000/api/stats

# Check if container is listening on correct interface
docker exec -it kubefeeds netstat -tlnp
```

### 4. Feed Processing Issues

#### **Issue**: No articles being collected
```bash
# Check feed sources status
curl http://localhost:3000/api/feeds

# Check application stats
curl http://localhost:3000/api/stats

# Manually test RSS parsing
node -e "
const Parser = require('rss-parser');
const parser = new Parser();
parser.parseURL('https://kubernetes.io/feed.xml')
  .then(feed => console.log('? RSS parsing works:', feed.items.length, 'items'))
  .catch(err => console.error('? RSS parsing failed:', err.message));
"
```

#### **Issue**: Articles not showing abstracts
```bash
# This indicates content processing issues
# Check if articles have content field populated
curl http://localhost:3000/api/articles | grep -o '"abstract":"[^"]*"' | head -5
```

### 5. Performance Issues

#### **Issue**: Slow application response
```bash
# Monitor resource usage
top | grep node
ps aux | grep node

# Check database size
ls -lh kubefeeds.db

# Monitor network requests
netstat -tuln | grep :3000
```

**Solutions:**
```bash
# Limit feed fetching frequency
# Edit app.js and change cron schedule from '0 */4 * * *' to '0 */6 * * *'

# Clean old articles (optional)
sqlite3 kubefeeds.db "DELETE FROM articles WHERE date(created_at) < date('now', '-30 days');"

# Add indexes if needed
sqlite3 kubefeeds.db "CREATE INDEX IF NOT EXISTS idx_published ON articles(published);"
```

## ? Debugging Commands

### Check Application Health
```bash
# Basic health check
curl -f http://localhost:3000/api/stats

# Detailed API test
curl -v http://localhost:3000/api/articles?limit=1

# Check all endpoints
endpoints=("/api/stats" "/api/feeds" "/api/articles" "/")
for endpoint in "${endpoints[@]}"; do
  echo "Testing $endpoint:"
  curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:3000$endpoint"
done
```

### View Logs and Status
```bash
# Application logs
tail -f kubefeeds.log

# System logs
journalctl -u kubefeeds -f  # if using systemd

# Process information
ps aux | grep node
netstat -tlnp | grep :3000
```

### Database Operations
```bash
# Open database
sqlite3 kubefeeds.db

# Useful queries
sqlite3 kubefeeds.db "SELECT COUNT(*) as total_articles FROM articles;"
sqlite3 kubefeeds.db "SELECT source, COUNT(*) as count FROM articles GROUP BY source;"
sqlite3 kubefeeds.db "SELECT title FROM articles ORDER BY created_at DESC LIMIT 5;"
```

## ? Getting Help

### Information to Collect
When reporting issues, please provide:

1. **Environment Information**
```bash
node --version
npm --version
curl --version
uname -a
```

2. **Application Status**
```bash
curl -s http://localhost:3000/api/stats
ls -la kubefeeds.*
```

3. **Recent Logs**
```bash
tail -50 kubefeeds.log
```

4. **GitHub Actions Logs**
- Go to the [Actions tab](https://github.com/collabnix/kubefeeds/actions)
- Click on the failing workflow run
- Download logs or copy relevant sections

### Support Channels
- ? **GitHub Issues**: [Create an issue](https://github.com/collabnix/kubefeeds/issues/new)
- ? **Discord**: Join the [Collabnix Discord](https://discord.gg/collabnix)
- ? **Email**: Contact [info@collabnix.com](mailto:info@collabnix.com)

## ? Additional Resources

- **GitHub Repository**: https://github.com/collabnix/kubefeeds
- **Docker Hub**: https://hub.docker.com/r/collabnix/kubefeeds
- **Collabnix Blog**: https://collabnix.com
- **Kubernetes Documentation**: https://kubernetes.io/docs/

---

**Updated**: This troubleshooting guide is maintained with the latest fixes and improvements.