const express = require('express');
const cors = require('cors');
const Parser = require('rss-parser');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const cron = require('node-cron');

const app = express();
const parser = new Parser();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Database setup
const db = new sqlite3.Database('kubefeeds.db');

// Initialize database
db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS articles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    link TEXT UNIQUE NOT NULL,
    abstract TEXT,
    content TEXT,
    published DATE,
    source TEXT,
    author TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS feeds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    url TEXT UNIQUE NOT NULL,
    active INTEGER DEFAULT 1,
    last_fetched DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);
});

// Kubernetes-related RSS feeds
const kubernetesFeedSources = [
  { name: 'Kubernetes Blog', url: 'https://kubernetes.io/feed.xml' },
  { name: 'CNCF Blog', url: 'https://www.cncf.io/feed/' },
  { name: 'Docker Blog', url: 'https://www.docker.com/blog/feed/' },
  { name: 'Red Hat OpenShift Blog', url: 'https://www.redhat.com/en/rss/blog/channel/red-hat-openshift' },
  { name: 'Platform9 Blog', url: 'https://platform9.com/blog/feed/' },
  { name: 'Rancher Blog', url: 'https://www.rancher.com/blog/rss.xml' },
  { name: 'Aqua Security Blog', url: 'https://blog.aquasec.com/rss.xml' },
  { name: 'Sysdig Blog', url: 'https://sysdig.com/blog/feed/' }
];

// Initialize feeds in database
function initializeFeeds() {
  kubernetesFeedSources.forEach(feed => {
    db.run('INSERT OR IGNORE INTO feeds (name, url) VALUES (?, ?)', [feed.name, feed.url]);
  });
}

// Generate abstract from content
function generateAbstract(content, title) {
  // Simple extractive summarization
  if (!content) return '';
  
  // Remove HTML tags
  const cleanContent = content.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
  
  // Split into sentences
  const sentences = cleanContent.split(/[.!?]+/).filter(s => s.trim().length > 20);
  
  // Get first 2-3 sentences or up to 200 characters
  let abstract = '';
  for (let sentence of sentences.slice(0, 3)) {
    if (abstract.length + sentence.length > 200) break;
    abstract += sentence.trim() + '. ';
  }
  
  return abstract.trim() || cleanContent.substring(0, 200) + '...';
}

// Fetch and parse RSS feed
async function fetchFeed(feedUrl, feedName) {
  try {
    console.log(`Fetching feed: ${feedName}`);
    const feed = await parser.parseURL(feedUrl);
    
    let newArticlesCount = 0;
    
    for (const item of feed.items) {
      // Filter Kubernetes-related content
      const title = item.title || '';
      const content = item.content || item.summary || item.description || '';
      const isKubernetesRelated = /kubernetes|k8s|container|docker|pod|deployment|helm|kubectl|cluster|microservice|devops|cloud.?native|cncf/i.test(title + ' ' + content);
      
      if (isKubernetesRelated) {
        const abstract = generateAbstract(content, title);
        
        db.run(`INSERT OR IGNORE INTO articles 
          (title, link, abstract, content, published, source, author) 
          VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [
            title,
            item.link,
            abstract,
            content.substring(0, 5000), // Limit content length
            item.pubDate || item.isoDate,
            feedName,
            item.creator || item.author || 'Unknown'
          ],
          function(err) {
            if (err && !err.message.includes('UNIQUE constraint failed')) {
              console.error('Error inserting article:', err);
            } else if (this.changes > 0) {
              newArticlesCount++;
            }
          }
        );
      }
    }
    
    // Update last fetched time
    db.run('UPDATE feeds SET last_fetched = CURRENT_TIMESTAMP WHERE url = ?', [feedUrl]);
    
    if (newArticlesCount > 0) {
      console.log(`Added ${newArticlesCount} new articles from ${feedName}`);
    }
    
  } catch (error) {
    console.error(`Error fetching feed ${feedName}:`, error.message);
  }
}

// Fetch all feeds
async function fetchAllFeeds() {
  console.log('Starting feed fetch cycle...');
  
  db.all('SELECT * FROM feeds WHERE active = 1', [], async (err, feeds) => {
    if (err) {
      console.error('Error getting feeds:', err);
      return;
    }
    
    for (const feed of feeds) {
      await fetchFeed(feed.url, feed.name);
      // Add delay between requests to be respectful
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
    
    console.log('Feed fetch cycle completed');
  });
}

// API Routes

// Get all articles with pagination
app.get('/api/articles', (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const offset = (page - 1) * limit;
  const search = req.query.search || '';
  
  let query = `SELECT * FROM articles`;
  let countQuery = `SELECT COUNT(*) as total FROM articles`;
  let params = [];
  
  if (search) {
    query += ` WHERE title LIKE ? OR abstract LIKE ? OR content LIKE ?`;
    countQuery += ` WHERE title LIKE ? OR abstract LIKE ? OR content LIKE ?`;
    const searchParam = `%${search}%`;
    params = [searchParam, searchParam, searchParam];
  }
  
  query += ` ORDER BY published DESC LIMIT ? OFFSET ?`;
  
  // Get total count
  db.get(countQuery, params, (err, countResult) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    
    // Get articles
    db.all(query, [...params, limit, offset], (err, articles) => {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      
      res.json({
        articles,
        totalCount: countResult.total,
        currentPage: page,
        totalPages: Math.ceil(countResult.total / limit)
      });
    });
  });
});

// Get article by ID
app.get('/api/articles/:id', (req, res) => {
  db.get('SELECT * FROM articles WHERE id = ?', [req.params.id], (err, article) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    
    if (!article) {
      res.status(404).json({ error: 'Article not found' });
      return;
    }
    
    res.json(article);
  });
});

// Get feed sources
app.get('/api/feeds', (req, res) => {
  db.all('SELECT * FROM feeds ORDER BY name', [], (err, feeds) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(feeds);
  });
});

// Add new feed
app.post('/api/feeds', (req, res) => {
  const { name, url } = req.body;
  
  if (!name || !url) {
    res.status(400).json({ error: 'Name and URL are required' });
    return;
  }
  
  db.run('INSERT INTO feeds (name, url) VALUES (?, ?)', [name, url], function(err) {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    
    res.json({ id: this.lastID, name, url });
    
    // Fetch the new feed immediately
    fetchFeed(url, name);
  });
});

// Manual feed refresh
app.post('/api/refresh', async (req, res) => {
  res.json({ message: 'Feed refresh started' });
  fetchAllFeeds();
});

// Statistics endpoint
app.get('/api/stats', (req, res) => {
  db.all(`
    SELECT 
      COUNT(*) as total_articles,
      COUNT(DISTINCT source) as total_sources,
      MAX(published) as latest_article,
      COUNT(CASE WHEN DATE(published) = DATE('now') THEN 1 END) as today_articles
    FROM articles
  `, [], (err, stats) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(stats[0]);
  });
});

// Serve React app
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Initialize the application
function initialize() {
  initializeFeeds();
  
  // Initial feed fetch after 5 seconds
  setTimeout(() => {
    fetchAllFeeds();
  }, 5000);
  
  // Schedule feed fetching every 4 hours
  cron.schedule('0 */4 * * *', () => {
    fetchAllFeeds();
  });
}

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`KubeFeeds server running on port ${PORT}`);
  console.log(`Visit http://localhost:${PORT} to view the portal`);
  initialize();
});

module.exports = app;