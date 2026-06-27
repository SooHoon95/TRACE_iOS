"""Domain logic shared by routers: resolve-or-create, aggregates, serialization."""
from collections.abc import Iterable

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from . import models, schemas
from .geo import haversine_m
from .storage import storage


async def resolve_or_create_place(
    db: AsyncSession, lat: float, lng: float, radius_m: float, name: str | None
) -> models.Place:
    """Snap to the nearest existing place within radius, else create one. Atomic per request."""
    places = (await db.execute(select(models.Place))).scalars().all()

    nearest: models.Place | None = None
    best: float | None = None
    for place in places:
        dist = haversine_m(place.latitude, place.longitude, lat, lng)
        if best is None or dist < best:
            best, nearest = dist, place

    if nearest is not None and best is not None and best <= radius_m:
        return nearest

    place = models.Place(
        ref_type="coordinate" if name is None else "poi",
        ref_provider_id=None if name is None else "mock",
        ref_name=name,
        latitude=lat,
        longitude=lng,
        display_name=name or "이름 없는 자리",
    )
    db.add(place)
    await db.flush()
    return place


async def author_nickname_map(
    db: AsyncSession, author_ids: Iterable[str]
) -> dict[str, str]:
    ids = list(set(author_ids))
    if not ids:
        return {}
    rows = (
        await db.execute(select(models.Profile).where(models.Profile.id.in_(ids)))
    ).scalars().all()
    return {p.id: p.nickname for p in rows}


async def place_to_out(db: AsyncSession, place: models.Place) -> schemas.PlaceOut:
    """Build a PlaceOut with aggregates computed over its public, non-hidden moments."""
    moments = (
        await db.execute(
            select(models.Moment)
            .where(
                models.Moment.place_id == place.id,
                models.Moment.visibility == "publicExhibit",
                models.Moment.hidden.is_(False),
            )
            .order_by(models.Moment.created_at.desc())
        )
    ).scalars().all()

    contributors = {m.author_id for m in moments}
    cover = moments[0].photo_ref if moments else None
    return schemas.PlaceOut(
        id=place.id,
        ref=schemas.PlaceRefOut(
            type=place.ref_type, provider_id=place.ref_provider_id, name=place.ref_name
        ),
        latitude=place.latitude,
        longitude=place.longitude,
        display_name=place.display_name,
        moment_count=len(moments),
        contributor_count=len(contributors),
        cover_photo_ref=cover,
        cover_photo_url=storage.url(cover) if cover else None,
        created_at=place.created_at,
    )


def moment_to_out(moment: models.Moment, author_nickname: str) -> schemas.MomentOut:
    return schemas.MomentOut(
        id=moment.id,
        place_id=moment.place_id,
        author_id=moment.author_id,
        author_nickname=author_nickname,
        photo_ref=moment.photo_ref,
        photo_url=storage.url(moment.photo_ref),
        caption=moment.caption,
        companion=moment.companion,
        vibe=moment.vibe,
        latitude=moment.latitude,
        longitude=moment.longitude,
        visibility=moment.visibility,
        created_at=moment.created_at,
    )
