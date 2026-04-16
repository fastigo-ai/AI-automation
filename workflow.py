from render_sdk import Workflows, Retry
from core.ingestion import KnowledgeIngestor
from utils.google_sheets import SheetManager
from core.database.manager import DatabaseManager
import asyncio

app = Workflows()
db = DatabaseManager()

@app.task(
    name="scrape_website",
    retry=Retry(max_retries=2, wait_duration_ms=5000),
    timeout_seconds=600,
    plan="standard"
)
def scrape_task(url: str, max_pages: int = 10):
    """
    Distributed task to scrape a website and ingest into Supabase.
    """
    print(f"[WORKFLOW] Starting scrape task for {url}")
    ingestor = KnowledgeIngestor(db)
    
    # Run the async ingestion in the synchronous task wrapper
    loop = asyncio.get_event_loop()
    loop.run_until_complete(ingestor.scrape_and_ingest(url, max_pages))
    
    return {"status": "completed", "url": url}

@app.task(
    name="capture_lead",
    retry=Retry(max_retries=3, wait_duration_ms=2000, backoff_scaling=2.0),
    timeout_seconds=60,
    plan="standard"
)
def capture_lead_task(name: str, service: str, details: str, session_id: str):
    """
    Distributed task to save lead info into Google Sheets.
    """
    print(f"[WORKFLOW] Starting lead capture for {name}")
    sheets = SheetManager()
    success = sheets.capture_lead(name, service, details, session_id)
    
    if not success:
        raise Exception("Failed to save lead to Google Sheets. Retrying...")
        
    return {"status": "saved", "name": name}

if __name__ == "__main__":
    app.start()
