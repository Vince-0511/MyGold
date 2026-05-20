from datetime import datetime
import os
import sys
import firebase_admin
from firebase_admin import credentials, firestore
import requests

# =========================================================================
# 1. INITIALIZE FIREBASE
# =========================================================================
try:
    cred = credentials.Certificate("./serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase initialized.")
except Exception as e:
    print(f"Firebase init failed: {e}")
    sys.exit(1)

GOLD_API_KEY = os.environ.get("GOLD_API_KEY")
NEWS_API_KEY = os.environ.get("NEWS_API_KEY")

if not GOLD_API_KEY or not NEWS_API_KEY:
    print("API keys missing from environment.")
    sys.exit(1)

failed = False

# =========================================================================
# 2. SYNC GOLD PRICE
# =========================================================================
print("\nFetching gold price...")
try:
    headers = {"x-access-token": GOLD_API_KEY, "Content-Type": "application/json"}
    response = requests.get("https://www.goldapi.io/api/XAU/MYR", headers=headers, timeout=15)
    response.raise_for_status()
    data = response.json()

    price_per_gram = data.get("price_gram_24k")
    if price_per_gram is None:
        raise ValueError("price_gram_24k missing from API response")

    today_str = datetime.now().strftime("%Y-%m-%d")
    db.collection("gold_history").document(today_str).set({
        "date": today_str,
        "price_per_gram": float(price_per_gram),
    })
    print(f"Gold price synced: RM {float(price_per_gram):.2f}/g for {today_str}")
except Exception as e:
    print(f"Gold price sync FAILED: {e}")
    failed = True

# =========================================================================
# 3. SYNC GOLD NEWS
# =========================================================================
print("\nFetching gold news...")
try:
    news_url = (
        "https://newsapi.org/v2/everything"
        "?q=(%22gold+price%22+OR+%22gold+market%22)+AND+finance"
        "&language=en"
        "&sortBy=relevancy"
        f"&apiKey={NEWS_API_KEY}"
    )
    response = requests.get(news_url, timeout=15)
    response.raise_for_status()
    articles = response.json().get("articles", [])[:5]

    if not articles:
        raise ValueError("No articles returned from NewsAPI")

    news_collection = db.collection("gold_news")
    batch = db.batch()

    for doc in news_collection.limit(400).stream():
        batch.delete(doc.reference)

    for index, art in enumerate(articles):
        batch.set(news_collection.document(), {
            "title": art.get("title"),
            "description": art.get("description"),
            "source": art.get("source", {}).get("name", "Finance News"),
            "url": art.get("url"),
            "published_at": art.get("publishedAt"),
            "order": index,
        })

    batch.commit()
    print(f"News synced: {len(articles)} articles written.")
except Exception as e:
    print(f"News sync FAILED: {e}")
    failed = True

# =========================================================================
# 4. EXIT
# =========================================================================
if failed:
    print("\nOne or more sync steps failed — see errors above.")
    sys.exit(1)

print("\nAll syncs completed successfully.")
