#!/usr/bin/env python3

from ai_models.api.openrouter_api import OpenRouterClient
import json

def test_openrouter():
    client = OpenRouterClient()
    data = client.create_chat_completion([
        {'role': 'system', 'content': 'You are a legal document analysis AI that generates realistic simulation data based on document content. Always return valid JSON.'},
        {'role': 'user', 'content': 'Generate simulation data for: Sample contract text for testing'}
    ], temperature=0.2, max_tokens=600, response_format={'type': 'json_object'})
    
    content = data.get('choices', [{}])[0].get('message', {}).get('content', '')
    print("Full response:")
    print(content)
    print("\n" + "="*50 + "\n")
    
    # Try to parse JSON
    try:
        obj = json.loads(content)
        print("JSON parsing successful!")
        print("Keys:", list(obj.keys()))
    except json.JSONDecodeError as e:
        print(f"JSON parsing failed: {e}")
        print(f"Error position: {e.pos}")
        print(f"Error line: {e.lineno}, column: {e.colno}")
        
        # Show context around error
        lines = content.split('\n')
        start = max(0, e.lineno - 3)
        end = min(len(lines), e.lineno + 3)
        print("\nContext around error:")
        for i in range(start, end):
            marker = ">>> " if i == e.lineno - 1 else "    "
            print(f"{marker}{i+1:2d}: {lines[i]}")

if __name__ == "__main__":
    test_openrouter()
