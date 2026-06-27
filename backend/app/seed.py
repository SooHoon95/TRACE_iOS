"""Seed demo Jeju data for a fresh deployment (idempotent).

    python -m app.seed     # run from backend/ with the venv active
"""
import asyncio

from sqlalchemy import func, select

from . import models
from .db import SessionLocal, init_models


async def run() -> None:
    await init_models()
    async with SessionLocal() as db:
        existing = (await db.execute(select(func.count(models.Place.id)))).scalar_one()
        if existing:
            print(f"already seeded ({existing} places) — skipping")
            return

        demo = models.Profile(nickname="지민", provider="guest")
        db.add(demo)
        await db.flush()

        seongsan = models.Place(
            ref_type="poi", ref_provider_id="mock", ref_name="성산일출봉",
            latitude=33.458, longitude=126.942, display_name="성산일출봉",
        )
        woljeong = models.Place(
            ref_type="poi", ref_provider_id="mock", ref_name="월정리 해변",
            latitude=33.556, longitude=126.795, display_name="월정리 해변",
        )
        db.add_all([seongsan, woljeong])
        await db.flush()

        db.add_all([
            models.Moment(
                place_id=seongsan.id, author_id=demo.id, photo_ref="seed/seongsan-1.jpg",
                caption="해돋이 봤어", vibe="scenic",
                latitude=33.458, longitude=126.942,
            ),
            models.Moment(
                place_id=woljeong.id, author_id=demo.id, photo_ref="seed/woljeong-1.jpg",
                caption="에메랄드 바다", vibe="calm",
                latitude=33.556, longitude=126.795,
            ),
        ])
        await db.commit()
        print("seeded 2 places + 2 moments (성산일출봉, 월정리 해변)")


if __name__ == "__main__":
    asyncio.run(run())
