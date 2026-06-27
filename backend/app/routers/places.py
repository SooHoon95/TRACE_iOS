"""Places: list, nearby, resolve-or-create, detail, and per-place exhibition feed."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from .. import models, schemas, service
from ..db import get_db
from ..geo import haversine_m
from ..security import get_current_user

router = APIRouter(prefix="/places", tags=["places"])


@router.get("", response_model=list[schemas.PlaceOut])
async def list_places(db: AsyncSession = Depends(get_db)):
    places = (await db.execute(select(models.Place))).scalars().all()
    return [await service.place_to_out(db, p) for p in places]


# Declared before /{place_id} so the literal paths win the route match.
@router.get("/nearby", response_model=list[schemas.PlaceOut])
async def nearby(
    lat: float, lng: float, radius_m: float = 1000.0, db: AsyncSession = Depends(get_db)
):
    places = (await db.execute(select(models.Place))).scalars().all()
    out = []
    for p in places:
        if haversine_m(p.latitude, p.longitude, lat, lng) <= radius_m:
            out.append(await service.place_to_out(db, p))
    return out


@router.post("/resolve", response_model=schemas.PlaceOut)
async def resolve(
    body: schemas.ResolvePlaceIn,
    user: models.Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    place = await service.resolve_or_create_place(
        db, body.latitude, body.longitude, body.radius_m, body.name
    )
    await db.commit()
    return await service.place_to_out(db, place)


@router.get("/{place_id}", response_model=schemas.PlaceOut)
async def get_place(place_id: str, db: AsyncSession = Depends(get_db)):
    place = await db.get(models.Place, place_id)
    if place is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "place not found")
    return await service.place_to_out(db, place)


@router.get("/{place_id}/moments", response_model=list[schemas.MomentOut])
async def place_moments(
    place_id: str,
    user: models.Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Exhibition feed: public moments + the viewer's own private ones, newest first."""
    moments = (
        await db.execute(
            select(models.Moment)
            .where(
                models.Moment.place_id == place_id,
                models.Moment.hidden.is_(False),
                or_(
                    models.Moment.visibility == "publicExhibit",
                    models.Moment.author_id == user.id,
                ),
            )
            .order_by(models.Moment.created_at.desc())
        )
    ).scalars().all()
    names = await service.author_nickname_map(db, (m.author_id for m in moments))
    return [service.moment_to_out(m, names.get(m.author_id, "여행자")) for m in moments]
