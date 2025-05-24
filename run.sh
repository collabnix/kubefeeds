#!/bin/bash

echo "? KubeFeeds Quick Setup"
echo "======================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "? Node.js not found. Please install Node.js first:"
    echo "   Visit: https://nodejs.org"
    exit 1
fi

echo "? Node.js found: $(node --version)"

# Create public directory and frontend if missing
mkdir -p public

if [ ! -f "public/index.html" ]; then
    echo "? Creating frontend file..."
    cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>KubeFeeds - Kubernetes News Aggregator</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; color: white; padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; padding: 40px 0; }
        .logo { font-size: 3rem; margin-bottom: 10px; }
        .subtitle { font-size: 1.2rem; opacity: 0.9; margin-bottom: 40px; }
        .stats { display: flex; justify-content: center; gap: 40px; margin: 40px 0; flex-wrap: wrap; }
        .stat { 
            background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; 
            text-align: center; min-width: 120px; backdrop-filter: blur(10px);
        }
        .stat-number { font-size: 2rem; font-weight: bold; margin-bottom: 5px; }
        .stat-label { font-size: 0.9rem; opacity: 0.8; }
        .loading { text-align: center; margin: 40px 0; }
        .spinner { 
            display: inline-block; width: 40px; height: 40px; margin: 20px;
            border: 4px solid rgba(255,255,255,.3); border-radius: 50%; 
            border-top-color: #fff; animation: spin 1s ease-in-out infinite; 
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .articles { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 20px; margin: 40px 0; }
        .article { 
            background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; 
            backdrop-filter: blur(10px); transition: transform 0.3s;
        }
        .article:hover { transform: translateY(-5px); }
        .article-title { font-size: 1.1rem; font-weight: bold; margin-bottom: 10px; line-height: 1.4; }
        .article-title a { color: white; text-decoration: none; }
        .article-title a:hover { text-decoration: underline; }
        .article-meta { font-size: 0.9rem; opacity: 0.7; margin-bottom: 15px; }
        .article-source { 
            background: rgba(255,255,255,0.2); padding: 4px 8px; border-radius: 15px; 
            font-size: 0.8rem; margin-right: 10px;
        }
        .article-abstract { line-height: 1.5; opacity: 0.9; }
        .status { text-align: center; margin: 40px 0; padding: 20px; background: rgba(255,255,255,0.1); border-radius: 10px; }
        .api-links { text-align: center; margin: 40px 0; }
        .api-links a { 
            color: white; text-decoration: none; margin: 0 15px; padding: 10px 20px; 
            background: rgba(255,255,255,0.2); border-radius: 20px; display: inline-block;
        }
        .api-links a:hover { background: rgba(255,255,255,0.3); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">? KubeFeeds</div>
            <div class="subtitle">Kubernetes News Aggregator</div>
        </div>
        
        <div class="stats" id="stats">
            <div class="stat">
                <div class="stat-number" id="total-articles">0</div>
                <div class="stat-label">Total Articles</div>
            </div>
            <div class="stat">
                <div class="stat-number" id="total-sources">0</div>
                <div class="stat-label">Sources</div>
            </div>
            <div class="stat">
                <div class="stat-number" id="today-articles">0</div>
                <div class="stat-label">Today</div>
            </div>
        </div>
        
        <div id="loading" class="loading">
            <div class="spinner"></div>
            <p>Loading Kubernetes feeds...</p>
        </div>
        
        <div id="status" class="status" style="display: none;">
            <p id="status-message">? Collecting Kubernetes articles from various sources...</p>
        </div>
        
        <div id="articles" class="articles"></div>
        
        <div class="api-links">
            <a href="/api/stats">? Statistics</a>
            <a href="/api/feeds">? Sources</a>
            <a href="/api/articles">? Articles API</a>
        </div>
    </div>

    <script>
        let articlesLoaded = false;
        
        async function loadStats() {
            try {
                const response = await fetch('/api/stats');
                const stats = await response.json();
                
                document.getElementById('total-articles').textContent = stats.total_articles || 0;
                document.getElementById('total-sources').textContent = stats.total_sources || 0;
                document.getElementById('today-articles').textContent = stats.today_articles || 0;
                
                document.getElementById('loading').style.display = 'none';
                document.getElementById('status').style.display = 'block';
                
                if (stats.total_articles > 0) {
                    document.getElementById('status-message').innerHTML = 
                        '? Portal is active! Found ' + stats.total_articles + ' Kubernetes articles.';
                    if (!articlesLoaded) {
                        loadArticles();
                    }
                } else {
                    document.getElementById('status-message').innerHTML = 
                        '? Feeds are being processed. New articles will appear soon...';
                }
            } catch (error) {
                document.getElementById('loading').style.display = 'none';
                document.getElementById('status').style.display = 'block';
                document.getElementById('status-message').innerHTML = 
                    '? Starting up... The application is initializing feeds.';
            }
        }
        
        async function loadArticles() {
            try {
                const response = await fetch('/api/articles?limit=12');
                const data = await response.json();
                
                if (data.articles && data.articles.length > 0) {
                    articlesLoaded = true;
                    const articlesDiv = document.getElementById('articles');
                    
                    articlesDiv.innerHTML = data.articles.map(article => `
                        <div class="article">
                            <div class="article-title">
                                <a href="${article.link}" target="_blank">${article.title}</a>
                            </div>
                            <div class="article-meta">
                                <span class="article-source">${article.source}</span>
                                ${new Date(article.published).toLocaleDateString()}
                            </div>
                            <div class="article-abstract">
                                ${article.abstract || 'Click to read the full article...'}
                            </div>
                        </div>
                    `).join('');
                }
            } catch (error) {
                console.log('Articles will load once feeds are processed');
            }
        }
        
        // Load stats immediately
        loadStats();
        
        // Refresh every 30 seconds
        setInterval(loadStats, 30000);
    </script>
</body>
</html>
EOF
    echo "? Created beautiful frontend"
fi

# Install dependencies
echo "? Installing dependencies..."
npm install

# Start the application
echo ""
echo "? Starting KubeFeeds..."
echo ""
echo "????????????????????????????????????????????????????????????????????????????"
echo "? Portal URL: http://localhost:3000"
echo "? API Stats: http://localhost:3000/api/stats"
echo "? Feeds: http://localhost:3000/api/feeds"
echo "? Articles: http://localhost:3000/api/articles"
echo "????????????????????????????????????????????????????????????????????????????"
echo ""
echo "? The application will start collecting Kubernetes feeds automatically."
echo "? Keep this terminal open and visit the URL above in your browser."
echo ""

node app.js