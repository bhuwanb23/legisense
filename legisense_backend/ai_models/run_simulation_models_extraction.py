import os
import sys
import json
from pathlib import Path
from typing import Dict, Any

# Bootstrap sys.path so this script also works when executed directly by file path
CURRENT_FILE = Path(__file__).resolve()
AI_MODELS_DIR = CURRENT_FILE.parent
BACKEND_DIR = AI_MODELS_DIR.parent
REPO_ROOT = BACKEND_DIR.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.append(str(REPO_ROOT))

from legisense_backend.ai_models.api.openrouter_api import OpenRouterClient
from legisense_backend.ai_models.parse_simulation_models_json import parse_models_json, ParseError


def run_extraction() -> Dict[str, Any]:
    base_dir = BACKEND_DIR
    models_path = base_dir / "api" / "models_db" / "simulation.py"
    prompt_path = base_dir / "ai_models" / "prompts" / "simulation_models_extraction_prompt.txt"
    out_dir = base_dir / "ai_models" / "output"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "simulation_models.json"

    models_text = models_path.read_text(encoding="utf-8")
    prompt_text = prompt_path.read_text(encoding="utf-8")

    system_msg = {
        "role": "system",
        "content": "You are a precise code analyst that outputs only strict JSON when asked."
    }

    user_content = (
        prompt_text
        + "\n\n--- FILE START ---\n"
        + models_text
        + "\n--- FILE END ---\n"
    )

    user_msg = {"role": "user", "content": user_content}

    client = OpenRouterClient()
    data = client.create_chat_completion(
        messages=[system_msg, user_msg],
        temperature=0.0,
        max_tokens=4000,
        response_format={"type": "json_object"},
    )

    content: str = data.get("choices", [{}])[0].get("message", {}).get("content", "")
    if not content:
        raise RuntimeError("Empty response content from OpenRouter")

    # Persist raw JSON
    out_file.write_text(content, encoding="utf-8")

    # Validate
    obj: Dict[str, Any] = parse_models_json(content)
    return obj


def main() -> None:
    obj = run_extraction()
    # Simple success summary
    print(json.dumps({
        "status": "ok",
        "models_count": len(obj.get("models", [])),
        "enums_count": len(obj.get("enums", [])),
        "relationships_count": len(obj.get("relationships", [])),
        "file": obj.get("file"),
    }, indent=2))


if __name__ == "__main__":
    main()
