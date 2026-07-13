from __future__ import annotations

import json
from typing import Any, Dict, List, Optional, Tuple


class ParseError(Exception):
    pass


def _require(obj: Dict[str, Any], key: str, expected_type: Tuple[type, ...]) -> Any:
    if key not in obj:
        raise ParseError(f"Missing required key: {key}")
    val = obj[key]
    if not isinstance(val, expected_type):
        exp = ", ".join(t.__name__ for t in expected_type)
        raise ParseError(f"Key '{key}' must be of type(s): {exp}")
    return val


def _optional(obj: Dict[str, Any], key: str, expected_type: Tuple[type, ...]) -> Any:
    if key not in obj:
        return None
    val = obj[key]
    if val is not None and not isinstance(val, expected_type):
        exp = ", ".join(t.__name__ for t in expected_type)
        raise ParseError(f"Key '{key}' must be of type(s): {exp}")
    return val


def parse_models_json(data: str) -> Dict[str, Any]:
    """
    Parse and lightly validate the JSON produced by
    run_simulation_models_extraction.py / document_simulation_prompt.txt.

    The real extraction output uses a session/timeline/penalty schema:

        {
          "session": {"title", "scenario", "parameters", "jurisdiction", ...},
          "timeline": [{"order", "title", "description", ...}],
          "penalty_forecast": [...],
          "exit_comparisons": [...],
          "risk_alerts": [...]
        }

    Returns the loaded dictionary if valid; raises ParseError otherwise.
    """
    try:
        obj = json.loads(data)
    except json.JSONDecodeError as e:
        raise ParseError(f"Invalid JSON: {e}") from e

    if not isinstance(obj, dict):
        raise ParseError("Top-level JSON must be an object")

    # Required root keys
    _require(obj, "session", (dict,))
    _optional(obj, "timeline", (list,))
    _optional(obj, "penalty_forecast", (list,))
    _optional(obj, "exit_comparisons", (list,))
    _optional(obj, "risk_alerts", (list,))

    # Validate session
    session = _require(obj, "session", (dict,))
    _require(session, "title", (str,))
    if "parameters" in session and session["parameters"] is not None:
        if not isinstance(session["parameters"], dict):
            raise ParseError("session.parameters must be an object or null")

    # Validate timeline entries
    for node in obj.get("timeline", []) or []:
        if not isinstance(node, dict):
            raise ParseError("each timeline node must be an object")
        _require(node, "order", (int,))
        _require(node, "title", (str,))
        _optional(node, "description", (str,))
        _optional(node, "detailed_description", (str,))
        if "risks" in node and node["risks"] is not None and not isinstance(node["risks"], list):
            raise ParseError("timeline node risks must be a list or null")

    # Validate penalty forecasts
    for forecast in obj.get("penalty_forecast", []) or []:
        if not isinstance(forecast, dict):
            raise ParseError("each penalty_forecast entry must be an object")
        _require(forecast, "label", (str,))

    # Validate exit comparisons
    for comparison in obj.get("exit_comparisons", []) or []:
        if not isinstance(comparison, dict):
            raise ParseError("each exit_comparison entry must be an object")
        _require(comparison, "label", (str,))

    # Validate risk alerts
    for alert in obj.get("risk_alerts", []) or []:
        if not isinstance(alert, dict):
            raise ParseError("each risk_alert entry must be an object")
        _require(alert, "message", (str,))

    return obj


def get_session(obj: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    session = obj.get("session")
    return session if isinstance(session, dict) else None


def list_timeline_nodes(obj: Dict[str, Any]) -> List[Dict[str, Any]]:
    return [n for n in obj.get("timeline", []) if isinstance(n, dict)]
