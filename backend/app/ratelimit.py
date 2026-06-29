"""In-process sliding-window rate limiting.

Single-instance friendly (OCI Always-Free is one process) — no Redis needed.
Swap `limiter` for a shared-store impl if the deployment ever scales out.
"""
from __future__ import annotations

import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request, status

from .config import get_settings


class SlidingWindowLimiter:
    """Per-key sliding-window counter held in memory."""

    def __init__(self) -> None:
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    def reset(self) -> None:
        """Drop all recorded hits (used by tests)."""
        self._hits.clear()

    def check(self, key: str, limit: int, window_s: float = 60.0) -> None:
        """Record a hit for `key`; raise 429 if it exceeds `limit` within the window.

        A non-positive `limit` disables throttling for that call.
        """
        if limit <= 0:
            return
        now = time.monotonic()
        hits = self._hits[key]
        cutoff = now - window_s
        while hits and hits[0] <= cutoff:
            hits.popleft()
        if len(hits) >= limit:
            raise HTTPException(
                status.HTTP_429_TOO_MANY_REQUESTS, "rate limit exceeded"
            )
        hits.append(now)


limiter = SlidingWindowLimiter()


def rate_limit(request: Request) -> None:
    """FastAPI dependency: throttle a client (by IP + path) on mutating endpoints."""
    settings = get_settings()
    client = request.client.host if request.client else "unknown"
    # Scope the bucket by path so one hot endpoint can't starve the others.
    limiter.check(f"{client}:{request.url.path}", settings.rate_limit_per_minute)
