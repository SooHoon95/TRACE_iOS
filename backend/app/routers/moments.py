"""Moments: home feed, create (claim), my moments, report/hide moderation."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import distinct, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from .. import models, schemas, service
from ..config import get_settings
from ..db import get_db
from ..ratelimit import rate_limit
from ..security import get_current_user

router = APIRouter(tags=["moments"])
settings = get_settings()


@router.get("/moments/feed", response_model=list[schemas.MomentOut])
async def feed(
    lat: float | None = None,
    lng: float | None = None,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
):
    """Recent public moments across all places (home activity feed)."""
    moments = (
        await db.execute(
            select(models.Moment)
            .where(
                models.Moment.visibility == "publicExhibit",
                models.Moment.hidden.is_(False),
            )
            .order_by(models.Moment.created_at.desc())
            .limit(limit)
        )
    ).scalars().all()
    names = await service.author_nickname_map(db, (m.author_id for m in moments))
    return [service.moment_to_out(m, names.get(m.author_id, "여행자")) for m in moments]


@router.post(
    "/moments",
    response_model=schemas.MomentOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(rate_limit)],
)
async def create_moment(
    body: schemas.MomentCreateIn,
    user: models.Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    place = await db.get(models.Place, body.place_id)
    if place is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "place not found")

    moment = models.Moment(
        place_id=body.place_id,
        author_id=user.id,
        photo_ref=body.photo_ref,
        caption=body.caption,
        companion=body.companion,
        vibe=body.vibe,
        latitude=body.latitude,
        longitude=body.longitude,
        visibility=body.visibility,
    )
    db.add(moment)
    await db.commit()
    await db.refresh(moment)
    return service.moment_to_out(moment, user.nickname)


@router.get("/me/moments", response_model=list[schemas.MomentOut])
async def my_moments(
    user: models.Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    moments = (
        await db.execute(
            select(models.Moment)
            .where(
                models.Moment.author_id == user.id,
                models.Moment.hidden.is_(False),
            )
            .order_by(models.Moment.created_at.desc())
        )
    ).scalars().all()
    return [service.moment_to_out(m, user.nickname) for m in moments]


@router.post(
    "/moments/{moment_id}/report",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(rate_limit)],
)
async def report_moment(
    moment_id: str,
    body: schemas.ReportIn,
    user: models.Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    moment = await db.get(models.Moment, moment_id)
    if moment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "moment not found")
    db.add(
        models.MomentReport(
            moment_id=moment_id, reporter_id=user.id, reason=body.reason
        )
    )
    await db.commit()

    # Auto-hide once enough DISTINCT users have reported it (T2.11 safety minimum).
    distinct_reporters = (
        await db.execute(
            select(func.count(distinct(models.MomentReport.reporter_id)))
            .where(models.MomentReport.moment_id == moment_id)
        )
    ).scalar_one()
    if distinct_reporters >= settings.report_hide_threshold and not moment.hidden:
        moment.hidden = True
        await db.commit()


@router.post(
    "/moments/{moment_id}/hide",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(rate_limit)],
)
async def hide_moment(
    moment_id: str,
    user: models.Profile = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    moment = await db.get(models.Moment, moment_id)
    if moment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "moment not found")
    if moment.author_id != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "only the author can hide")
    moment.hidden = True
    await db.commit()
