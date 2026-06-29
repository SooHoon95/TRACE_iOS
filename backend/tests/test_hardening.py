"""Hardening: liveness/readiness probes, request-id, rate limiting, error shape."""
import asyncio
import json

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.config import get_settings
from app.main import app, unhandled_exception_handler
from app.ratelimit import SlidingWindowLimiter, limiter, rate_limit


def test_health_is_liveness_only():
    with TestClient(app) as client:
        r = client.get("/health")
        assert r.status_code == 200
        assert r.json()["status"] == "ok"


def test_ready_reports_db_up():
    with TestClient(app) as client:
        r = client.get("/ready")
        assert r.status_code == 200
        assert r.json() == {"status": "ready", "db": "up"}


def test_every_response_carries_a_request_id():
    with TestClient(app) as client:
        r = client.get("/health")
        assert r.headers.get("X-Request-ID")


def test_inbound_request_id_is_echoed():
    with TestClient(app) as client:
        r = client.get("/health", headers={"X-Request-ID": "trace-123"})
        assert r.headers["X-Request-ID"] == "trace-123"


def test_sliding_window_limiter_blocks_after_limit():
    lim = SlidingWindowLimiter()
    lim.check("k", 2)  # 1st — ok
    lim.check("k", 2)  # 2nd — ok
    with pytest.raises(HTTPException) as exc:
        lim.check("k", 2)  # 3rd — over the limit
    assert exc.value.status_code == 429
    # a different key keeps its own independent budget
    lim.check("other", 2)


def test_limiter_disabled_when_limit_non_positive():
    lim = SlidingWindowLimiter()
    for _ in range(100):
        lim.check("k", 0)  # 0 = disabled, never raises


def test_rate_limit_dependency_is_wired_into_a_mutating_endpoint():
    """Override the limiter with a strict stub to prove the dependency actually runs."""
    limiter.reset()
    calls = {"n": 0}

    def strict(request=None):
        calls["n"] += 1
        if calls["n"] > 2:
            raise HTTPException(429, "rate limit exceeded")

    app.dependency_overrides[rate_limit] = strict
    try:
        with TestClient(app) as client:
            assert client.post("/auth/guest", json={"nickname": "a"}).status_code == 200
            assert client.post("/auth/guest", json={"nickname": "b"}).status_code == 200
            r = client.post("/auth/guest", json={"nickname": "c"})
            assert r.status_code == 429
            assert r.json()["detail"] == "rate limit exceeded"
    finally:
        app.dependency_overrides.pop(rate_limit, None)
        limiter.reset()


def test_unhandled_exception_handler_returns_standard_json():
    resp = asyncio.run(unhandled_exception_handler(None, RuntimeError("kaboom")))
    assert resp.status_code == 500
    assert json.loads(resp.body) == {"detail": "internal server error"}


def test_generic_exception_handler_is_registered():
    assert app.exception_handlers.get(Exception) is unhandled_exception_handler


def test_real_limiter_throttles_over_http():
    """End-to-end: the real limiter + real dependency 429 a hot client (no stubs)."""
    settings = get_settings()
    original = settings.rate_limit_per_minute
    settings.rate_limit_per_minute = 2  # mutate the cached singleton for this test
    limiter.reset()
    try:
        with TestClient(app) as client:
            assert client.post("/auth/guest", json={"nickname": "a"}).status_code == 200
            assert client.post("/auth/guest", json={"nickname": "b"}).status_code == 200
            r = client.post("/auth/guest", json={"nickname": "c"})
            assert r.status_code == 429
            assert r.json()["detail"] == "rate limit exceeded"
    finally:
        settings.rate_limit_per_minute = original
        limiter.reset()
