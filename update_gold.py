from datetime import datetime
import os
import json
import firebase_admin
from firebase_admin import credentials, firestore
import requests

# =========================================================================
# 1. INITIALIZE CONNECTION TO FIRESTORE (CLOUD & LOCAL COMPATIBLE)
# =========================================================================
try:
    # Check if we are running inside GitHub Actions environment
    firebase_creds_json = os.environ.get('FIREBASE_SERVICE_ACCOUNT_KEY')

    if firebase_creds_json:
        # Cloud Execution: Parse service account credentials directly from GitHub Secrets
        creds_dict = json.loads(firebase_creds_json)
        cred = credentials.Certificate(creds_dict)
        firebase_admin.initialize_app(cred)
        print("🔒 Firebase initialized via GitHub Secrets.")
    else:
        # Local Execution Fallback: Look for the local JSON file on your machine
        cred = credentials.Certificate("./serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
        print("💻 Firebase initialized via local serviceAccountKey.json file.")

    db = firestore.client()
except Exception as e:
    print(f"Error initializing Firebase: {e}")
    exit(1)

# =========================================================================
# CONFIGURATION KEYS
# =========================================================================
GOLD_API_KEY = "goldapi-62dcfd30611b04562f7f26b5c5e0940e-io"
NEWS_API_KEY = "708bda35f02f4bb7aee6155728220b07" # Get free from newsapi.org

# =========================================================================
# PART A: FETCH & SYNC LIVE GOLD PRICE
# =========================================================================
print("\nContacting GoldAPI servers...")
try:
    gold_headers = {"x-access-token": GOLD_API_KEY, "Content-Type": "application/json"}
    response = requests.get("https://www.goldapi.io/api/XAU/MYR", headers=gold_headers)
    response.raise_for_status()
    gold_data = response.json()
    
    price_per_gram = float(gold_data.get("price_gram_24k"))
    today_str = datetime.now().strftime("%Y-%m-%d")
    
    print(f"Live Rate Found: RM {price_per_gram:.2f} /g")
    
    db.collection("gold_history").document(today_str).set({
        "date": today_str,
        "price_per_gram": price_per_gram
    })
    print("Success! Gold price node synced.")
except Exception as e:
    print(f"Gold Price Sync Failed: {e}")

# =========================================================================
# PART B: FETCH & SYNC LIVE GOLD NEWS
# =========================================================================
print("\nContacting NewsAPI servers for market headlines...")
try:
    # Enforces that "gold price" or "gold market" MUST be the main topic, filtering out random news
    news_url = f"https://newsapi.org/v2/everything?q=(%22gold+price%22+OR+%22gold+market%22+OR+%22bullion%22)+AND+finance&language=en&sortBy=relevancy&apiKey={NEWS_API_KEY}"
    response = requests.get(news_url)
    response.raise_for_status()
    articles = response.json().get("articles", [])[:5] # Grab top 5 newest articles
    
    news_collection = db.collection("gold_news")
    
    # Clear out yesterday's news so your list stays fresh
    old_news = news_collection.stream()
    for doc in old_news:
        doc.reference.delete()
        
    # Batch upload the new headlines
    for index, art in enumerate(articles):
        news_collection.add({
            "title": art.get("title"),
            "description": art.get("description"),
            "source": art.get("source", {}).get("name", "Finance News"),
            "url": art.get("url"),
            "published_at": art.get("publishedAt"),
            "order": index # Helps sort them in Flutter chronologically
        })
    print(f"Success! Uploaded {len(articles)} fresh articles to 'gold_news' collection.")

except Exception as e:
    print(f"Gold News Sync Failed: {e}")