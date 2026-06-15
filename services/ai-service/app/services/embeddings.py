import os
import json
import hashlib
import numpy as np
from typing import List

EMBEDDING_DIM = 384
_model = None


def _get_model():
    global _model
    if _model is None:
        try:
            from sentence_transformers import SentenceTransformer
            _model = SentenceTransformer("all-MiniLM-L6-v2")
        except ImportError:
            _model = "hash"
    return _model


def generate_embedding(text: str) -> List[float]:
    model = _get_model()
    if model == "hash":
        return _hash_embedding(text)
    embedding = model.encode(text, normalize_embeddings=True)
    return embedding.tolist()


def generate_embeddings(texts: List[str]) -> List[List[float]]:
    model = _get_model()
    if model == "hash":
        return [_hash_embedding(t) for t in texts]
    embeddings = model.encode(texts, normalize_embeddings=True, batch_size=32)
    return embeddings.tolist()


def _hash_embedding(text: str) -> List[float]:
    hash_bytes = hashlib.sha256(text.encode()).digest()
    vec = []
    for i in range(EMBEDDING_DIM):
        byte_val = hash_bytes[i % len(hash_bytes)]
        vec.append((byte_val / 128.0) - 1.0)
    norm = sum(x * x for x in vec) ** 0.5
    return [x / norm for x in vec] if norm > 0 else vec


def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
    words = text.split()
    chunks = []
    start = 0
    while start < len(words):
        end = start + chunk_size
        chunk = " ".join(words[start:end])
        if chunk.strip():
            chunks.append(chunk)
        start = end - overlap
    return chunks
