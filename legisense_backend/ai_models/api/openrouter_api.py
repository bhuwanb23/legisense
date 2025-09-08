import os
import json
from pathlib import Path
from typing import List, Dict, Any, Optional

import requests


class OpenRouterClient:
    """Minimal OpenRouter chat completions client.

    Reads API key from OPENROUTER_API_KEY and supports custom model selection.
    """

    def __init__(self, api_key: Optional[str] = None, model: Optional[str] = None):
        key = api_key or os.getenv("OPENROUTER_API_KEY", "")
        if not key:
            try:
                base_dir = Path(__file__).resolve().parents[2]
                key_file = base_dir / "api_keys"
                if key_file.exists():
                    key = key_file.read_text(encoding="utf-8").strip()
            except Exception:
                pass
        self.api_key = key
        if not self.api_key:
            raise RuntimeError("OPENROUTER_API_KEY is not set")
        self.model = model or os.getenv("OPENROUTER_MODEL", "deepseek/deepseek-chat-v3.1:free")
        self.base_url = "https://openrouter.ai/api/v1/chat/completions"

    def create_chat_completion(self, messages: List[Dict[str, str]], temperature: float = 0.2, max_tokens: int = 2000, response_format: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
            "X-Title": os.getenv("OPENROUTER_APP_TITLE", "Legisense"),
        }
        payload: Dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if response_format is not None:
            payload["response_format"] = response_format

        # Simple debug print to verify model/key presence in logs
        print(json.dumps({"openrouter_request": {"model": self.model, "has_key": bool(self.api_key)}}))

        resp = requests.post(self.base_url, headers=headers, data=json.dumps(payload), timeout=90)
        if resp.status_code >= 400:
            print(f"[OpenRouter] Error {resp.status_code}: {resp.text}")
            raise RuntimeError(f"OpenRouter error {resp.status_code}: {resp.text}")
        data = resp.json()
        return data
