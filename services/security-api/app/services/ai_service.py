import json
import httpx
from app.core.config import settings
from app.core.database import frappe_get, frappe_post

class AIService:
    def __init__(self):
        self.llm_url = settings.ai_service_url # Assuming this is in config
        self.llm_api_key = settings.ai_service_key

    async def generate_estimate(self, technical_assignment: str):
        # 1. Search for relevant items in the price list based on TA
        # This is a simplified search. In a real RAG, we'd use embeddings.
        relevant_items = await self._find_relevant_items(technical_assignment)
        
        # 2. Build the prompt for LLM
        prompt = f"""
        You are a professional security systems engineer. 
        Based on the following Technical Assignment (TA) and the available product catalog, 
        create a preliminary cost estimate.
        
        TA: {technical_assignment}
        
        Available Catalog (Item Code | Name | Retail Price):
        {relevant_items}
        
        Rules:
        1. Only use items from the provided catalog.
        2. If a necessary item is missing, add it to the 'missing_items' list.
        3. Provide the result in JSON format:
        {{
          "items": [
            {{"item_code": "CODE", "quantity": 1, "price": 100, "reason": "why this item"}},
            ...
          ],
          "missing_items": ["what is missing"],
          "total_estimated_cost": 0,
          "engineer_comments": "Professional advice"
        }}
        """
        
        # 3. Call LLM
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                self.llm_url,
                json={"prompt": prompt, "api_key": self.llm_api_key},
                timeout=30.0
            )
            if resp.status_code == 200:
                return resp.json()
            raise Exception(f"AI Service Error: {resp.text}")

    async def _find_relevant_items(self, ta: str) -> str:
        # Basic keyword-based search in Item DocType
        # In production, this would use the AI Service's vector search (pgvector)
        items_list = []
        
        # We fetch items from ERPNext. To keep it simple, we'll fetch top 500 items 
        # or use a search endpoint.
        result = await frappe_get("/api/resource/Item?fields=[\"item_code\",\"item_name\",\"retail_price\"]&limit_page_length=500")
        data = result.get("data", [])
        
        # Simple keyword matching
        keywords = ta.lower().split()
        for item in data:
            name = item.get("item_name", "").lower()
            if any(kw in name for kw in keywords if len(kw) > 3):
                items_list.append(f"{item['item_code']} | {item['item_name']} | {item.get('retail_price', 'N/A')}")
        
        return "\n".join(items_list) if items_list else "No matching items found in catalog."

ai_service = AIService()
