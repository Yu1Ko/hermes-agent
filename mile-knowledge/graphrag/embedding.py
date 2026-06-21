"""Embedding API wrapper — replaces sentence-transformers with HTTP API calls."""

import logging
from typing import Any

import numpy as np
import requests

from graphrag.config import EMBEDDING_API_KEY, EMBEDDING_API_BASE, EMBEDDING_API_MODEL

logger = logging.getLogger(__name__)

# Max texts per API call (safety limit for URL length / payload size)
_BATCH_SIZE = 100


def embed_texts(texts: list[str]) -> np.ndarray:
    """Encode a list of texts via the embedding API.

    Returns (n, dim) numpy array. Raises RuntimeError on API failure.
    """
    if not texts:
        return np.empty((0, 0))

    if not EMBEDDING_API_KEY:
        raise RuntimeError("EMBEDDING_API_KEY not set — cannot call embedding API")

    all_vectors: list[list[float]] = []

    # Batch to respect API limits
    for i in range(0, len(texts), _BATCH_SIZE):
        batch = texts[i : i + _BATCH_SIZE]
        try:
            resp = requests.post(
                f"{EMBEDDING_API_BASE}/embeddings",
                headers={
                    "Authorization": f"Bearer {EMBEDDING_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={"model": EMBEDDING_API_MODEL, "input": batch},
                timeout=60,
            )
            resp.raise_for_status()
            data: dict[str, Any] = resp.json()
        except requests.RequestException:
            logger.exception("Embedding API call failed for batch %d–%d", i, i + len(batch))
            raise RuntimeError(f"Embedding API unreachable: {EMBEDDING_API_BASE}")

        if "data" not in data:
            raise RuntimeError(f"Unexpected API response: {data}")

        for entry in data["data"]:
            all_vectors.append(entry["embedding"])

    return np.array(all_vectors, dtype=np.float32)


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Compute cosine similarity between two sets of vectors.

    a: (m, d)  b: (n, d)  → returns (m, n) similarity matrix.
    """
    a_norm = a / (np.linalg.norm(a, axis=1, keepdims=True) + 1e-10)
    b_norm = b / (np.linalg.norm(b, axis=1, keepdims=True) + 1e-10)
    return np.dot(a_norm, b_norm.T)
