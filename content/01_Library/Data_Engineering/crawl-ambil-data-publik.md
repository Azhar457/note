---
title: Usage
tags:
- web-scraping
- data-collection
- open-data
- api
- crawl
- research-automation
- google-dorking
- rss
- wayback-machine
- anti-detection
aliases:
- Public Data Harvesting
- Crawl & Scrape
- Research Pipeline
created: 2026-08-01
updated: 2026-08-01
status: complete
cssclasses:
  - wide-table
  - callout
---

> [!abstract] Crawl & Ambil Data Publik — Operational Guide
> DeepResearch AI premium tidak melakukan magic. Mereka mengambil data dari **sumber publik** — web pages, API terbuka, arsip, PDF, dan database publik — lalu merangkumnya dengan LLM. Catatan ini mendokumentasikan seluruh pipeline untuk melakukan hal yang sama secara mandiri: dari discovery sumber data, crawling, parsing, aggregation, sampai synthesis — tanpa bergantung ke platform berbayar.

---

## Daftar Isi
1. [[#1. Discovery — Menemukan Sumber Data Publik]]
2. [[#2. Web Scraping — BeautifulSoup, Scrapy, Playwright]]
3. [[#3. API Publik & Open Data Portals]]
4. [[#4. Search Engine Operators — Google Dorking & Beyond]]
5. [[#5. RSS, Feed & Real-Time Aggregation]]
6. [[#6. Arsip Web — Wayback Machine, Common Crawl]]
7. [[#7. PDF & Document Parsing Pipeline]]
8. [[#8. Social Media & Forum Data (Legal Boundaries)]]
9. [[#9. Anti-Detection & Rate Limiting]]
10. [[#10. Automated Research Pipeline — End-to-End]]
11. [[#11. Legal & Ethical Boundaries]]
12. [[#12. References]]

---

## 1. Discovery — Menemukan Sumber Data Publik

### 1.1 Taxonomy Sumber Data Publik

| Kategori | Contoh Sumber | Format | Update Frequency |
|:---------|:--------------|:------:|:----------------:|
| Government Open Data | data.gov, data.go.id, EU ODP | CSV, JSON, API | Daily/Weekly |
| Academic | arXiv, PubMed, Google Scholar | PDF, XML | Daily |
| News Media | Reuters, AP, BBC | HTML, RSS | Real-time |
| Financial | Yahoo Finance, FRED, World Bank | CSV, JSON | Daily |
| Legal | CourtListener, PACER (free tier) | PDF, XML | Event-driven |
| Social | Reddit, HN, StackExchange | JSON, HTML | Real-time |
| Web Pages | Blogs, company sites, docs | HTML | Variable |
| Arsip | Wayback Machine, Common Crawl | WARC, HTML | Monthly |

### 1.2 Discovery Tools

**Search Engine:**
```
Google: "site:github.com filetype:json dataset"
Bing: "filetype:csv site:gov climate data"
DuckDuckGo: "intitle:index.of data.csv"
```

**Dataset Search Engines:**
```
Google Dataset Search: datasetsearch.research.google.com
Kaggle: kaggle.com/datasets
UCI ML Repository: archive.ics.uci.edu/ml
AWS Open Data: registry.opendata.aws
```

**Academic Discovery:**
```
arXiv API: export.arxiv.org/api/query
CrossRef API: api.crossref.org/works
Semantic Scholar: api.semanticscholar.org
OpenAlex: openalex.org
```

---

## 2. Web Scraping — BeautifulSoup, Scrapy, Playwright

### 2.1 Static Scraping — BeautifulSoup

**Use case:** Halaman HTML statis, tidak ada JavaScript rendering.

```python
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse

class StaticCrawler:
    def __init__(self, base_url, max_depth=2, delay=1.0):
        self.base_url = base_url
        self.max_depth = max_depth
        self.delay = delay
        self.visited = set()
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (ResearchBot/1.0; +https://example.com/bot)'
        })
    
    def crawl(self, url=None, depth=0):
        if url is None:
            url = self.base_url
        if depth > self.max_depth or url in self.visited:
            return []
        self.visited.add(url)
        try:
            resp = self.session.get(url, timeout=10)
            resp.raise_for_status()
        except Exception as e:
            return [{'url': url, 'error': str(e)}]
        soup = BeautifulSoup(resp.text, 'html.parser')
        data = {
            'url': url,
            'title': soup.title.string if soup.title else '',
            'text': soup.get_text(separator=' ', strip=True),
            'links': []
        }
        for link in soup.find_all('a', href=True):
            absolute = urljoin(url, link['href'])
            if self._same_domain(absolute):
                data['links'].append(absolute)
        results = [data]
        import time
        for link in data['links'][:10]:
            time.sleep(self.delay)
            results.extend(self.crawl(link, depth + 1))
        return results
    
    def _same_domain(self, url):
        return urlparse(url).netloc == urlparse(self.base_url).netloc

# Usage
crawler = StaticCrawler('https://example.com/docs', max_depth=2)
pages = crawler.crawl()
```

### 2.2 Dynamic Scraping — Playwright

**Use case:** Halaman yang render dengan JavaScript (React, Vue, Angular).

```python
from playwright.sync_api import sync_playwright
import time

def scrape_dynamic(url, wait_for=None):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(
            user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
        )
        page.goto(url, wait_until='networkidle')
        if wait_for:
            page.wait_for_selector(wait_for, timeout=10000)
        for _ in range(3):
            page.evaluate('window.scrollBy(0, window.innerHeight)')
            time.sleep(0.5)
        content = {
            'url': url,
            'title': page.title(),
            'text': page.inner_text('body'),
            'html': page.content()
        }
        browser.close()
        return content
```

### 2.3 Large-Scale Scraping — Scrapy

**Use case:** Crawl ribuan halaman dengan concurrency, pipeline, dan middleware.

```python
import scrapy
from scrapy.crawler import CrawlerProcess

class ResearchSpider(scrapy.Spider):
    name = 'research'
    allowed_domains = ['example.com']
    start_urls = ['https://example.com/articles']
    custom_settings = {
        'DOWNLOAD_DELAY': 1,
        'CONCURRENT_REQUESTS': 4,
        'ROBOTSTXT_OBEY': True,
        'FEED_FORMAT': 'jsonlines',
        'FEED_URI': 'output.jsonl'
    }
    def parse(self, response):
        for article in response.css('article'):
            yield {
                'title': article.css('h2::text').get(),
                'url': response.urljoin(article.css('a::attr(href)').get()),
                'date': article.css('time::attr(datetime)').get(),
                'summary': article.css('.summary::text').get(),
            }
        next_page = response.css('a.next::attr(href)').get()
        if next_page:
            yield response.follow(next_page, self.parse)

process = CrawlerProcess()
process.crawl(ResearchSpider)
process.start()
```

### 2.4 Content Extraction — Trafilatura

**Masalah:** Raw HTML berisi navigation, ads, footer. Perlu extract main content.

```python
import trafilatura

def extract_article(url):
    downloaded = trafilatura.fetch_url(url)
    result = trafilatura.extract(
        downloaded,
        include_comments=False,
        include_tables=True,
        include_images=False,
        deduplicate=True,
        target_language='en'
    )
    return result

# Trafilatura accuracy:
# P(main content extracted | news article) ≈ 0.92
# P(main content extracted | blog post) ≈ 0.88
```

---

## 3. API Publik & Open Data Portals

### 3.1 REST API Pattern

```python
import requests
import time

class APIClient:
    def __init__(self, base_url, api_key=None, rate_limit=1.0):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.rate_limit = rate_limit
        self.session = requests.Session()
        if api_key:
            self.session.headers['Authorization'] = f'Bearer {api_key}'
    
    def get(self, endpoint, params=None):
        url = f'{self.base_url}/{endpoint.lstrip("/")}'
        time.sleep(self.rate_limit)
        resp = self.session.get(url, params=params, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        if isinstance(data, dict) and 'next' in data:
            while data.get('next'):
                time.sleep(self.rate_limit)
                next_resp = self.session.get(data['next'], timeout=30)
                next_data = next_resp.json()
                if 'results' in data and 'results' in next_data:
                    data['results'].extend(next_data['results'])
                data['next'] = next_data.get('next')
        return data

# Example: arXiv API
arxiv = APIClient('http://export.arxiv.org/api', rate_limit=3.0)
papers = arxiv.get('query', {
    'search_query': 'cat:cs.AI',
    'start': 0,
    'max_results': 100,
    'sortBy': 'submittedDate',
    'sortOrder': 'descending'
})
```

### 3.2 Open Data Portals

**World Bank API:**
```
Endpoint: api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD
Parameters: date=2020:2023, format=json, per_page=1000
Data: GDP per country per year
```

**FRED (Federal Reserve Economic Data):**
```
Endpoint: api.stlouisfed.org/fred/series/observations
Parameters: series_id=GDP, api_key=YOUR_KEY, file_type=json
Data: US economic time series
```

**OpenStreetMap (Overpass API):**
```
Query language: Overpass QL
[overpass-api.de/api/interpreter]
[out:json];
node["amenity"="restaurant"](around:1000,40.7128,-74.0060);
out;
Data: POI locations
```

### 3.3 GraphQL APIs

**Pattern:**
```python
query = "query { repository(owner: \"torvalds\", name: \"linux\") { stargazerCount issues(states: OPEN) { totalCount } pullRequests(states: MERGED) { totalCount } } }"

resp = requests.post(
    'https://api.github.com/graphql',
    json={'query': query},
    headers={'Authorization': 'Bearer TOKEN'}
)
```

---

## 4. Search Engine Operators — Google Dorking & Beyond

### 4.1 Google Advanced Operators

| Operator | Fungsi | Contoh |
|:---------|:-------|:-------|
| site: | Batasi ke domain | site:arxiv.org "transformer" |
| filetype: | Filter file type | filetype:pdf "machine learning" |
| intitle: | Kata di title | intitle:"annual report" 2024 |
| inurl: | Kata di URL | inurl:api documentation |
| intext: | Kata di body | intext:"API key" tutorial |
| cache: | Lihat cache | cache:example.com |
| related: | Site serupa | related:github.com |
| before: | Sebelum tanggal | before:2024-01-01 climate |
| after: | Setelah tanggal | after:2024-01-01 AI |
| "exact" | Exact phrase | "large language model" |
| -exclude | Exclude term | python -snake -monty |
| OR | Either term | (AI OR "machine learning") ethics |

### 4.2 Programmatic Search

**Google Custom Search API (100 queries/day free):**
```python
import requests

def google_search(query, api_key, cx, num=10):
    url = 'https://www.googleapis.com/customsearch/v1'
    params = {
        'key': api_key,
        'cx': cx,
        'q': query,
        'num': num
    }
    resp = requests.get(url, params=params)
    return resp.json()

# DuckDuckGo (no API key needed)
def ddg_search(query, max_results=10):
    from duckduckgo_search import DDGS
    with DDGS() as ddgs:
        return list(ddgs.text(query, max_results=max_results))
```

### 4.3 Academic Search

**Semantic Scholar API:**
```python
import requests

def search_papers(query, fields=None, limit=100):
    if fields is None:
        fields = ['title', 'authors', 'year', 'abstract', 'citationCount', 'openAccessPdf']
    url = 'https://api.semanticscholar.org/graph/v1/paper/search'
    params = {
        'query': query,
        'fields': ','.join(fields),
        'limit': limit
    }
    resp = requests.get(url, params=params)
    return resp.json()

# Example: get top 100 papers on transformer
papers = search_papers('transformer architecture', limit=100)
```

**OpenAlex:**
```python
def openalex_search(query):
    url = 'https://api.openalex.org/works'
    params = {
        'search': query,
        'per-page': 100,
        'sort': 'cited_by_count:desc'
    }
    resp = requests.get(url, params=params)
    return resp.json()
```

---

## 5. RSS, Feed & Real-Time Aggregation

### 5.1 RSS Feed Parsing

```python
import feedparser

def parse_feed(url):
    feed = feedparser.parse(url)
    entries = []
    for entry in feed.entries:
        entries.append({
            'title': entry.get('title', ''),
            'link': entry.get('link', ''),
            'published': entry.get('published', ''),
            'summary': entry.get('summary', ''),
            'content': entry.get('content', [{}])[0].get('value', '')
        })
    return entries

# Major news RSS feeds
feeds = [
    'https://feeds.reuters.com/reuters/topNews',
    'https://feeds.bbci.co.uk/news/rss.xml',
    'https://hnrss.org/frontpage',
    'https://www.technologyreview.com/feed/',
]

all_entries = []
for feed_url in feeds:
    all_entries.extend(parse_feed(feed_url))
```

### 5.2 Real-Time Stream Processing

**Pattern untuk high-frequency feeds:**
```python
import asyncio
import aiohttp
import feedparser

async def fetch_feed(session, url):
    async with session.get(url) as resp:
        text = await resp.text()
        return feedparser.parse(text)

async def aggregate_feeds(feed_urls):
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_feed(session, url) for url in feed_urls]
        results = await asyncio.gather(*tasks)
        return results

# Usage
feeds = ['url1', 'url2', 'url3']
results = asyncio.run(aggregate_feeds(feeds))
```

---

## 6. Arsip Web — Wayback Machine, Common Crawl

### 6.1 Wayback Machine API

```python
import requests

def wayback_snapshots(url, from_date=None, to_date=None):
    # Get all archived snapshots of a URL
    cdx_url = 'http://web.archive.org/cdx/search/cdx'
    params = {
        'url': url,
        'output': 'json',
        'collapse': 'timestamp:8'
    }
    if from_date:
        params['from'] = from_date
    if to_date:
        params['to'] = to_date
    resp = requests.get(cdx_url, params=params)
    data = resp.json()
    snapshots = []
    for row in data[1:]:
        snapshots.append({
            'timestamp': row[1],
            'url': row[2],
            'status': row[4],
            'archive_url': f'https://web.archive.org/web/{row[1]}/{row[2]}'
        })
    return snapshots

# Get historical versions of a page
snaps = wayback_snapshots('https://example.com/about', from_date='20200101')
```

### 6.2 Common Crawl

**Dataset:**
```
Monthly crawl: ~3-4 billion web pages
Format: WARC (Web ARChive)
Size: ~300 TB per month
Access: S3 (AWS us-east-1, no egress cost)
```

**Query via Athena:**
```sql
SELECT url, fetch_time, content_mime_type
FROM ccindex
WHERE crawl = 'CC-MAIN-2024-10'
  AND subset = 'warc'
  AND url_host_tld = 'gov'
  AND content_languages = 'ind'
LIMIT 1000;
```

**Python access:**
```python
import requests

def get_common_crawl_segments(crawl_id='CC-MAIN-2024-10'):
    url = f'https://index.commoncrawl.org/{crawl_id}-index'
    params = {
        'url': '*.gov/*',
        'output': 'json'
    }
    resp = requests.get(url, params=params)
    return resp.json()
```

---

## 7. PDF & Document Parsing Pipeline

### 7.1 PDF Text Extraction

```python
import fitz  # PyMuPDF
import pdfplumber

def extract_pdf_text(pdf_path):
    doc = fitz.open(pdf_path)
    pages = []
    for page_num in range(len(doc)):
        page = doc[page_num]
        text = page.get_text('dict')
        pages.append({
            'page': page_num + 1,
            'text': text,
            'images': len(page.get_images()),
            'tables': []
        })
    doc.close()
    return pages

def extract_tables(pdf_path):
    tables = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            page_tables = page.extract_tables()
            for table in page_tables:
                tables.append(table)
    return tables
```

### 7.2 Document Conversion Pipeline

```python
from docx import Document
import pandas as pd
import json

def parse_document(file_path):
    ext = file_path.split('.')[-1].lower()
    if ext == 'pdf':
        return extract_pdf_text(file_path)
    elif ext == 'docx':
        doc = Document(file_path)
        return {'paragraphs': [p.text for p in doc.paragraphs]}
    elif ext == 'csv':
        return pd.read_csv(file_path).to_dict('records')
    elif ext == 'xlsx':
        return pd.read_excel(file_path, sheet_name=None)
    elif ext == 'json':
        with open(file_path) as f:
            return json.load(f)
    else:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            return {'text': f.read()}
```

---

## 8. Social Media & Forum Data (Legal Boundaries)

### 8.1 Reddit API (PRAW)

```python
import praw

reddit = praw.Reddit(
    client_id='YOUR_ID',
    client_secret='YOUR_SECRET',
    user_agent='ResearchBot/1.0'
)

def collect_subreddit_posts(subreddit_name, limit=1000):
    subreddit = reddit.subreddit(subreddit_name)
    posts = []
    for post in subreddit.hot(limit=limit):
        posts.append({
            'title': post.title,
            'text': post.selftext,
            'score': post.score,
            'comments': post.num_comments,
            'created': post.created_utc,
            'url': post.url
        })
    return posts

# Note: Reddit API has rate limits
# 100 requests per minute for OAuth
```

### 8.2 Hacker News API

```python
import requests

def get_top_stories(n=100):
    top_ids = requests.get(
        'https://hacker-news.firebaseio.com/v0/topstories.json'
    ).json()[:n]
    stories = []
    for story_id in top_ids:
        story = requests.get(
            f'https://hacker-news.firebaseio.com/v0/item/{story_id}.json'
        ).json()
        stories.append(story)
    return stories
```

### 8.3 StackExchange API

```python
def search_stackexchange(site='stackoverflow', query='python', pagesize=100):
    url = 'https://api.stackexchange.com/2.3/search'
    params = {
        'order': 'desc',
        'sort': 'votes',
        'intitle': query,
        'site': site,
        'pagesize': pagesize
    }
    resp = requests.get(url, params=params)
    return resp.json()
```

---

## 9. Anti-Detection & Rate Limiting

### 9.1 Respectful Crawling

**robots.txt:**
```python
from urllib.robotparser import RobotFileParser
from urllib.parse import urlparse

def can_fetch(url, user_agent='*'):
    rp = RobotFileParser()
    rp.set_url(f'{urlparse(url).scheme}://{urlparse(url).netloc}/robots.txt')
    rp.read()
    return rp.can_fetch(user_agent, url)
```

**Rate limiting formula:**
```
Minimum delay = Crawl-delay dari robots.txt (default: 1s)
Polite delay = max(1s, Crawl-delay)

Untuk site dengan Crawl-delay: 5
-> Max 12 requests/minute = 720 requests/hour
```

### 9.2 Rotating User Agents & Proxies

```python
import random
import requests
import time

USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
]

class PoliteSession(requests.Session):
    def __init__(self):
        super().__init__()
        self.headers['User-Agent'] = random.choice(USER_AGENTS)
    
    def get(self, url, **kwargs):
        time.sleep(random.uniform(1, 3))
        return super().get(url, **kwargs)
```

### 9.3 Handling CAPTCHA

**Strategies:**
```
1. Slow down: reduce request rate
2. Use headless browser with stealth plugins
3. Respect the site: if CAPTCHA appears, stop and manual
4. Use official API instead of scraping
```

**Playwright stealth:**
```python
from playwright_stealth import stealth_sync

browser = p.chromium.launch()
page = browser.new_page()
stealth_sync(page)
```

---

## 10. Automated Research Pipeline — End-to-End

### 10.1 Architecture

```
+-------------------------------------------------------------+
|                    RESEARCH PIPELINE                         |
+-------------------------------------------------------------+
|                                                              |
|  +-------------+    +-------------+    +-------------+     |
|  |   QUERY     |--->|  DISCOVERY  |--->|   CRAWL     |     |
|  |  (topic)    |    | (search/API)|    | (scrape)    |     |
|  +-------------+    +-------------+    +------+------+     |
|                                                |            |
|  +-------------+    +-------------+    +-------v-------+     |
|  |  SYNTHESIS  |<---|   RANKING   |<---|   PARSE     |     |
|  |   (LLM)     |    |  (relevance)|    | (extract)   |     |
|  +------+------+    +-------------+    +-------------+     |
|         |                                                    |
|  +-------v-------+                                            |
|  |   OUTPUT    |                                            |
|  | (markdown)  |                                            |
|  +-------------+                                            |
|                                                              |
+-------------------------------------------------------------+
```

### 10.2 Full Implementation

```python
import os
import json
import time
import requests
from bs4 import BeautifulSoup
from duckduckgo_search import DDGS
import trafilatura

class ResearchBot:
    def __init__(self, max_sources=20):
        self.max_sources = max_sources
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (ResearchBot/1.0)'
        })
    
    def discover(self, query):
        # Step 1: Discover sources via search
        sources = []
        with DDGS() as ddgs:
            results = ddgs.text(query, max_results=self.max_sources)
            for r in results:
                sources.append({
                    'title': r['title'],
                    'url': r['href'],
                    'snippet': r['body']
                })
        return sources
    
    def crawl(self, sources):
        # Step 2: Crawl and extract content
        documents = []
        for src in sources:
            try:
                time.sleep(2)  # polite delay
                downloaded = trafilatura.fetch_url(src['url'])
                text = trafilatura.extract(downloaded, include_comments=False)
                if text and len(text) > 500:
                    documents.append({
                        'title': src['title'],
                        'url': src['url'],
                        'content': text[:10000],
                        'length': len(text)
                    })
            except Exception as e:
                continue
        return documents
    
    def synthesize(self, query, documents):
        # Step 3: Synthesize findings
        return {
            'query': query,
            'sources_count': len(documents),
            'total_words': sum(len(d['content'].split()) for d in documents),
            'documents': documents
        }
    
    def research(self, query):
        # Full pipeline
        print(f'Researching: {query}')
        sources = self.discover(query)
        print(f'Found {len(sources)} sources')
        documents = self.crawl(sources)
        print(f'Crawled {len(documents)} documents')
        result = self.synthesize(query, documents)
        return result

# Usage
bot = ResearchBot(max_sources=15)
result = bot.research("latest advances in quantum computing 2024")
print(f'Total words collected: {result["total_words"]}')
```

### 10.3 Integration dengan LLM Local

```python
# After collecting documents, feed to local LLM for synthesis
def generate_report(documents, query, llm_endpoint='http://localhost:11434'):
    context = '\n\n'.join([
        f"Source: {d['url']}\n{d['content'][:3000]}"
        for d in documents[:5]
    ])
    
    prompt = f'Based on the following sources, write a comprehensive report on: {query}\n\nSources:\n{context}\n\nPlease provide: 1. Executive summary 2. Key findings 3. Technical details 4. Sources cited'
    
    resp = requests.post(
        f'{llm_endpoint}/api/generate',
        json={
            'model': 'llama3',
            'prompt': prompt,
            'stream': False
        }
    )
    return resp.json()['response']
```

---

## 11. Legal & Ethical Boundaries

### 11.1 What is Legal

| Activity | Legal? | Notes |
|:---------|:------:|:------|
| Scraping public pages | Yes | No login required, no TOS violation |
| Using public APIs | Yes | Within rate limits |
| Reading RSS feeds | Yes | Designed for consumption |
| Using Wayback Machine | Yes | Explicitly allowed |
| Common Crawl data | Yes | Open dataset |
| Government open data | Yes | FOIA / open data laws |
| Academic open access | Yes | CC-BY licenses |
| Scraping behind login | Gray | Depends on TOS |
| Bypassing CAPTCHA | No | CFAA violation (US) |
| Scraping private data | No | GDPR, CCPA violation |
| DDoS-style crawling | No | Computer fraud |

### 11.2 Best Practices

```
1. Check robots.txt before crawling
2. Respect rate limits (max 1 req/s untuk site kecil)
3. Identify yourself via User-Agent
4. Don't scrape personal data
5. Don't bypass authentication
6. Cache results untuk avoid repeated requests
7. Follow site's Terms of Service
```

---

## 12. References

1. Mitchell, R. (2018). *Web Scraping with Python* (2nd ed.). O'Reilly Media. — BeautifulSoup, Scrapy, Selenium.

2. Zheng, Q. (2022). *Python Web Scraping Cookbook*. Packt. — Advanced scraping patterns.

3. Common Crawl Foundation. (2024). *Common Crawl Data Format*. commoncrawl.org. — WARC format & access patterns.

4. Internet Archive. (2024). *Wayback Machine CDX API Documentation*. archive.org. — Historical web access.

5. Reddit Inc. (2024). *Reddit API Documentation*. reddit.com/dev/api. — PRAW & REST API.

6. Zuboff, S. (2019). *The Age of Surveillance Capitalism*. PublicAffairs. — Context etis data collection.

7. Lawrence, D. (2023). *The Art of Web Scraping*. Independently published. — Anti-detection techniques.

## Koneksi ke Vault

| Catatan | Koneksi |
|:--------|:--------|
| [[osint-resource-index]] | OSINT tools overlap dengan data collection |
| [[document-parsing-for-rag]] | PDF & HTML parsing untuk RAG pipeline |
| [[advanced-chunking-strategies-deepdive]] | Chunking hasil crawl untuk RAG |
| [[hybrid-search-vector-keyword]] | Index hasil crawl untuk search |
| [[ai-evaluation-framework]] | Evaluasi kualitas hasil research |
