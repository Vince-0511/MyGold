from datetime import datetime
import os
import firebase_admin
from firebase_admin import credentials, firestore
import requests

# =========================================================================
# 1. INITIALIZE CONNECTION
# =========================================================================
try:
    # GitHub Actions will create this file in the root directory
    cred = credentials.Certificate("./serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase initialized successfully.")
except Exception as e:
    print(f"❌ Error initializing Firebase: {e}")
    exit(1)

# =========================================================================
# 2. CONFIGURATION (FETCHED FROM ENVIRONMENT VARIABLES)
# =========================================================================
# These will be passed in from your GitHub Action secrets
GOLD_API_KEY = os.environ.get("GOLD_API_KEY")
NEWS_API_KEY = os.environ.get("NEWS_API_KEY")

if not GOLD_API_KEY or not NEWS_API_KEY:
    print("❌ Error: API Keys not found in environment variables.")
    exit(1)

# =========================================================================
# 3. PART A: FETCH & SYNC LIVE GOLD PRICE
# =========================================================================
print("\nContacting GoldAPI servers...")
try:
    gold_headers = {"x-access-token": GOLD_API_KEY, "Content-Type": "application/json"}
    response = requests.get("https://www.goldapi.io/api/XAU/MYR", headers=gold_headers)
    response.raise_for_status()
    gold_data = response.json()
    
    price_per_gram = float(gold_data.get("price_gram_24k"))
    today_str = datetime.now().strftime("%Y-%m-%d")
    
    db.collection("gold_history").document(today_str).set({
        "date": today_str,
        "price_per_gram": price_per_gram
    })
    print(f"Success! Gold price synced: RM {price_per_gram:.2f} /g")
except Exception as e:
    print(f"Gold Price Sync Failed: {e}")

# =========================================================================
# 4. PART B: FETCH & SYNC LIVE GOLD NEWS
# =========================================================================
print("\nContacting NewsAPI servers...")
try:
    news_url = f"https://newsapi.org/v2/everything?q=(%22gold+price%22+OR+%22gold+market%22)+AND+finance&language=en&sortBy=relevancy&apiKey={NEWS_API_KEY}"
    response = requests.get(news_url)
    response.raise_for_status()
    articles = response.json().get("articles", [])[:5]
    
    news_collection = db.collection("gold_news")
    batch = db.batch()
    
    # 🎯 FIX: Limit stream to 400 to prevent exceeding Firestore's 500-write batch limit
    old_news = news_collection.limit(400).stream()
    for doc in old_news:
        batch.delete(doc.reference)
        
    for index, art in enumerate(articles):
        new_doc_ref = news_collection.document() 
        batch.set(new_doc_ref, {
            "title": art.get("title"),
            "description": art.get("description"),
            "source": art.get("source", {}).get("name", "Finance News"),
            "url": art.get("url"),
            "published_at": art.get("publishedAt"),
            "order": index
        })
        
    batch.commit()
    print(f"Success! Atomically synced {len(articles)} articles.")

except Exception as e:
    print(f"Gold News Sync Failed: {e}")