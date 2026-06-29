"""Auth: anonymous guest sessions + Apple/Kakao OIDC token exchange."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .. import models, schemas
from ..db import get_db
from ..providers.apple import verify_apple
from ..providers.kakao import verify_kakao
from ..ratelimit import rate_limit
from ..security import create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


def _auth_out(user: models.Profile) -> schemas.AuthOut:
    return schemas.AuthOut(
        access_token=create_access_token(user.id),
        user=schemas.UserOut(
            id=user.id, nickname=user.nickname, provider=user.provider, email=user.email
        ),
    )


@router.post("/guest", response_model=schemas.AuthOut, dependencies=[Depends(rate_limit)])
async def guest(body: schemas.GuestIn, db: AsyncSession = Depends(get_db)):
    user = models.Profile(nickname=body.nickname or "게스트", provider="guest")
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return _auth_out(user)


@router.post("/oauth", response_model=schemas.AuthOut, dependencies=[Depends(rate_limit)])
async def oauth(body: schemas.OAuthIn, db: AsyncSession = Depends(get_db)):
    provider = body.provider.lower()
    if provider == "apple":
        info = verify_apple(body.token)
    elif provider == "kakao":
        info = await verify_kakao(body.token)
    else:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "unsupported provider")

    subject = info["subject"]
    existing = (
        await db.execute(
            select(models.Profile).where(
                models.Profile.provider == provider,
                models.Profile.provider_subject == subject,
            )
        )
    ).scalar_one_or_none()

    if existing is not None:
        user = existing
    else:
        user = models.Profile(
            nickname=body.nickname or info.get("nickname") or "여행자",
            provider=provider,
            provider_subject=subject,
            email=info.get("email"),
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return _auth_out(user)


@router.get("/me", response_model=schemas.UserOut)
async def me(user: models.Profile = Depends(get_current_user)):
    return schemas.UserOut(
        id=user.id, nickname=user.nickname, provider=user.provider, email=user.email
    )
