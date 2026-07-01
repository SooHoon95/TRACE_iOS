"""Google Sign-In token exchange wiring (verification itself is mocked — no network)."""
from fastapi import HTTPException, status
from fastapi.testclient import TestClient

from app import routers
from app.main import app


def test_google_oauth_creates_user(monkeypatch):
    # Stand in for the real JWKS verification so the test needs no network / real token.
    def fake_verify(_token: str) -> dict:
        return {"subject": "google-sub-1", "email": "a@gmail.com", "nickname": "구글러"}

    monkeypatch.setattr(routers.auth, "verify_google", fake_verify)

    with TestClient(app) as client:
        r = client.post("/auth/oauth", json={"provider": "google", "token": "any"})
        assert r.status_code == 200, r.text
        body = r.json()
        assert body["access_token"]
        assert body["user"]["provider"] == "google"
        assert body["user"]["nickname"] == "구글러"


def test_google_oauth_same_subject_is_idempotent(monkeypatch):
    def fake_verify(_token: str) -> dict:
        return {"subject": "google-sub-2", "email": "b@gmail.com", "nickname": "구글러2"}

    monkeypatch.setattr(routers.auth, "verify_google", fake_verify)

    with TestClient(app) as client:
        first = client.post("/auth/oauth", json={"provider": "google", "token": "t"}).json()
        second = client.post("/auth/oauth", json={"provider": "google", "token": "t"}).json()
        assert first["user"]["id"] == second["user"]["id"], "same google subject → same user"


def test_google_oauth_invalid_token_is_401(monkeypatch):
    def fake_verify(_token: str) -> dict:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "google token invalid")

    monkeypatch.setattr(routers.auth, "verify_google", fake_verify)

    with TestClient(app) as client:
        r = client.post("/auth/oauth", json={"provider": "google", "token": "bad"})
        assert r.status_code == 401


def test_unknown_provider_is_400():
    with TestClient(app) as client:
        r = client.post("/auth/oauth", json={"provider": "myspace", "token": "x"})
        assert r.status_code == 400
