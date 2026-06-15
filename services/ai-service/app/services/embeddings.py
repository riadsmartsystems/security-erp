import hashlib
import math
import re
from typing import List

EMBEDDING_DIM = 384


def generate_embedding(text: str) -> List[float]:
    words = re.findall(r'\w+', text.lower())
    word_freq = {}
    for w in words:
        word_freq[w] = word_freq.get(w, 0) + 1

    vec = [0.0] * EMBEDDING_DIM
    for word, freq in word_freq.items():
        h = int(hashlib.md5(word.encode()).hexdigest(), 16)
        idx = h % EMBEDDING_DIM
        vec[idx] += math.log(1 + freq)

    for i in range(EMBEDDING_DIM):
        h = int(hashlib.sha256(f"{i}".encode()).hexdigest(), 16)
        vec[i] *= (1 + (h % 1000) / 1000.0)

    norm = math.sqrt(sum(x * x for x in vec))
    if norm > 0:
        vec = [x / norm for x in vec]
    return vec


def generate_embeddings(texts: List[str]) -> List[List[float]]:
    return [generate_embedding(t) for t in texts]


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
