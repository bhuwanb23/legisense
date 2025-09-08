import os
import json
from typing import List, Dict, Any, Optional

import requests


class OpenRouterClient:
    """Minimal OpenRouter chat completions client.

    Reads API key from OPENROUTER_API_KEY and supports custom model selection.
    """

    def __init__(self, api_key: Optional[str] = None, model: Optional[str] = None):
        self.api_key = api_key or os.getenv("OPENROUTER_API_KEY", "")
        if not self.api_key:
            raise RuntimeError("OPENROUTER_API_KEY is not set")
        self.model = model or os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini")
        self.base_url = "https://openrouter.ai/api/v1/chat/completions"

    def create_chat_completion(self, messages: List[Dict[str, str]], temperature: float = 0.2, max_tokens: int = 2000, response_format: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload: Dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if response_format is not None:
            payload["response_format"] = response_format

        resp = requests.post(self.base_url, headers=headers, data=json.dumps(payload), timeout=60)
        if resp.status_code >= 400:
            raise RuntimeError(f"OpenRouter error {resp.status_code}: {resp.text}")
        data = resp.json()
        return data
