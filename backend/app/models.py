"""ORM models. UUID PKs stored as String(36) for SQLite/Postgres portability."""
from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import DateTime, Float, ForeignKey, Index, String, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


def _uuid() -> str:
    return str(uuid4())


def _now() -> datetime:
    return datetime.now(timezone.utc)


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    nickname: Mapped[str] = mapped_column(String(80), default="여행자")
    provider: Mapped[str] = mapped_column(String(20), default="guest")  # apple|kakao|guest
    provider_subject: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)


class Place(Base):
    __tablename__ = "places"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    ref_type: Mapped[str] = mapped_column(String(20))  # poi|coordinate
    ref_provider_id: Mapped[str | None] = mapped_column(String(120), nullable=True)
    ref_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    latitude: Mapped[float] = mapped_column(Float)
    longitude: Mapped[float] = mapped_column(Float)
    display_name: Mapped[str] = mapped_column(String(200))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)


class Moment(Base):
    __tablename__ = "moments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    place_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("places.id", ondelete="CASCADE"), index=True
    )
    author_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("profiles.id", ondelete="CASCADE"), index=True
    )
    photo_ref: Mapped[str] = mapped_column(String(400))
    caption: Mapped[str | None] = mapped_column(Text, nullable=True)
    companion: Mapped[str | None] = mapped_column(String(40), nullable=True)
    vibe: Mapped[str | None] = mapped_column(String(40), nullable=True)
    latitude: Mapped[float] = mapped_column(Float)
    longitude: Mapped[float] = mapped_column(Float)
    visibility: Mapped[str] = mapped_column(String(20), default="publicExhibit")  # publicExhibit|privateOnly
    hidden: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)


class MomentReport(Base):
    __tablename__ = "moment_reports"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    moment_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("moments.id", ondelete="CASCADE"), index=True
    )
    reporter_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("profiles.id", ondelete="CASCADE")
    )
    reason: Mapped[str | None] = mapped_column(String(200), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)


Index("ix_moments_place_created", Moment.place_id, Moment.created_at.desc())
Index("ix_moments_author_created", Moment.author_id, Moment.created_at.desc())
