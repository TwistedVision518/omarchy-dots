#!/usr/bin/env python3
import json
import os
import re
import sys
import tempfile
from pathlib import Path

HOME = Path.home()
AGENT_FILE = HOME / ".config/omarchy/defaults/agent"
CODEX_HOME = Path(os.environ.get("CODEX_HOME", HOME / ".codex"))
USAGE_DIR = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "omarchy/agents/usage"

DEFAULT_MODELS = {
    "copilot": ["auto", "gpt-5.4", "gpt-5.3-codex", "gpt-5.2"],
    "codex": ["gpt-6-astra", "gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna", "gpt-5.5"],
    "claude": ["sonnet", "opus", "haiku"],
    "gemini": ["gemini-2.5-pro", "gemini-2.5-flash"],
    "opencode": ["anthropic/claude-sonnet-4-5", "openai/gpt-5", "opencode/big-pickle"],
}


def agent():
    try:
        value = AGENT_FILE.read_text().strip()
        return value or "copilot"
    except OSError:
        return "copilot"


def json_config(path):
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def model_for(name):
    if name == "codex":
        try:
            match = re.search(r'^model\s*=\s*"([^"]+)"', (CODEX_HOME / "config.toml").read_text(), re.M)
            return match.group(1) if match else ""
        except OSError:
            return ""
    paths = {
        "copilot": HOME / ".copilot/settings.json",
        "claude": HOME / ".claude/settings.json",
        "gemini": HOME / ".gemini/settings.json",
        "opencode": HOME / ".config/opencode/opencode.json",
    }
    return str(json_config(paths[name]).get("model", ""))


def write_json_model(path, model):
    data = json_config(path)
    data["model"] = model
    path.parent.mkdir(parents=True, exist_ok=True)
    atomic_write(path, json.dumps(data, indent=2) + "\n", 0o600)


def atomic_write(path, text, mode=0o600):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as handle:
            handle.write(text)
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def set_agent(name):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", name) or name not in DEFAULT_MODELS:
        raise SystemExit("Unsupported agent")
    atomic_write(AGENT_FILE, name + "\n")


def set_model(name, model):
    if name == "codex":
        config = CODEX_HOME / "config.toml"
        text = config.read_text() if config.exists() else ""
        line = f'model = "{model}"'
        text = re.sub(r'^model\s*=.*$', line, text, count=1, flags=re.M)
        if line not in text:
            text = line + "\n" + text
        atomic_write(config, text)
    else:
        paths = {
            "copilot": HOME / ".copilot/settings.json",
            "claude": HOME / ".claude/settings.json",
            "gemini": HOME / ".gemini/settings.json",
            "opencode": HOME / ".config/opencode/opencode.json",
        }
        write_json_model(paths[name], model)


def status():
    name = agent()
    record = json_config(USAGE_DIR / f"{name}.json")
    limits = [x for x in record.get("limits", []) if isinstance(x, dict) and isinstance(x.get("percent"), (int, float))]
    binding = max(limits, key=lambda x: x.get("percent", 0), default=None)
    print(json.dumps({
        "agent": name,
        "model": model_for(name),
        "models": DEFAULT_MODELS[name],
        "todayTokens": record.get("todayTotalTokens", 0),
        "modelUsage": record.get("modelUsage", {}),
        "remainingPercent": None if binding is None else max(0, round((1 - binding["percent"]) * 100)),
        "limitLabel": "" if binding is None else binding.get("label", binding.get("title", "Account limit")),
        "usageStatus": record.get("usageStatusText", ""),
    }))


if len(sys.argv) == 1 or sys.argv[1] == "status":
    status()
elif sys.argv[1] == "switch-agent" and len(sys.argv) == 3:
    set_agent(sys.argv[2])
    status()
elif sys.argv[1] == "switch-model" and len(sys.argv) == 3:
    set_model(agent(), sys.argv[2])
    status()
else:
    raise SystemExit("usage: model_switcher.py [status|switch-agent AGENT|switch-model MODEL]")
