"""Configuration for MiLe GraphRAG."""

import os
from pathlib import Path


def _load_dotenv(path: Path) -> None:
    """Minimal dotenv loader — reads KEY=VALUE pairs."""
    if not path.is_file():
        return
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip("\"'")
        if key and key not in os.environ:
            os.environ[key] = value


ENV_FILE = Path.home() / ".hermes" / ".env"
_load_dotenv(ENV_FILE)

DEEPSEEK_API_KEY = os.environ.get("V4FLASH_API_KEY") or os.environ.get("DEEPSEEK_API_KEY", "")
DEEPSEEK_BASE_URL = os.environ.get("V4FLASH_BASE_URL") or os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com/v1")
DEEPSEEK_MODEL = os.environ.get("V4FLASH_MODEL") or os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")

# Embedding API (方案3: mnapi.com)
EMBEDDING_API_KEY = os.environ.get("EMBEDDING_API_KEY", "")
EMBEDDING_API_BASE = os.environ.get(
    "EMBEDDING_API_BASE", "https://api.mnapi.com/v1"
)
EMBEDDING_API_MODEL = os.environ.get("EMBEDDING_API_MODEL", "text-embedding-3-small")

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
GRAPH_PATH = DATA_DIR / "graph.pkl"
EMBEDDINGS_PATH = DATA_DIR / "embeddings.npz"
COMMUNITIES_PATH = DATA_DIR / "communities.json"

DATA_DIR.mkdir(parents=True, exist_ok=True)

# Layer 4: Auto prompt optimisation — model used for analysing error patterns
# and suggesting System Prompt / SOUL.md changes. Set these env vars to use
# a model of your choice (not DeepSeek by default).
PROMPT_OPT_MODEL = os.environ.get("PROMPT_OPT_MODEL", "claude-opus-4-7")
PROMPT_OPT_API_KEY = os.environ.get("PROMPT_OPT_API_KEY", "")
PROMPT_OPT_BASE_URL = os.environ.get("PROMPT_OPT_BASE_URL", "https://ai.centos.hk")
