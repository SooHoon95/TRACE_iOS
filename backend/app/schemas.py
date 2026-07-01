"""Request/response DTOs. Shapes are designed to map 1:1 onto the iOS Domain models."""
from datetime import datetime

from pydantic import BaseModel


# ── Auth ──────────────────────────────────────────────────────────────────────
class UserOut(BaseModel):
    id: str
    nickname: str
    provider: str  # apple | kakao | guest
    email: str | None = None


class AuthOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class GuestIn(BaseModel):
    nickname: str | None = None


class OAuthIn(BaseModel):
    provider: str  # "apple" | "kakao" | "google"
    token: str     # Apple/Google id_token (JWT) or Kakao access token
    nickname: str | None = None


# ── Places ────────────────────────────────────────────────────────────────────
class PlaceRefOut(BaseModel):
    type: str  # poi | coordinate
    provider_id: str | None = None
    name: str | None = None


class PlaceOut(BaseModel):
    id: str
    ref: PlaceRefOut
    latitude: float
    longitude: float
    display_name: str
    moment_count: int = 0
    contributor_count: int = 0
    cover_photo_ref: str | None = None
    cover_photo_url: str | None = None
    created_at: datetime


class ResolvePlaceIn(BaseModel):
    latitude: float
    longitude: float
    radius_m: float = 20.0
    name: str | None = None


# ── Moments ───────────────────────────────────────────────────────────────────
class MomentOut(BaseModel):
    id: str
    place_id: str
    author_id: str
    author_nickname: str
    photo_ref: str
    photo_url: str | None = None
    caption: str | None = None
    companion: str | None = None
    vibe: str | None = None
    latitude: float
    longitude: float
    visibility: str  # publicExhibit | privateOnly
    created_at: datetime


class MomentCreateIn(BaseModel):
    place_id: str
    photo_ref: str
    latitude: float
    longitude: float
    caption: str | None = None
    companion: str | None = None
    vibe: str | None = None
    visibility: str = "publicExhibit"


class ReportIn(BaseModel):
    reason: str | None = None


class PhotoOut(BaseModel):
    ref: str
    url: str | None = None
