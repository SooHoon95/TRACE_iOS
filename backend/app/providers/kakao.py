"""Verify a Kakao access token by calling Kakao's user endpoint."""
import httpx
from fastapi import HTTPException, status

_KAKAO_ME = "https://kapi.kakao.com/v2/user/me"


async def verify_kakao(access_token: str) -> dict:
    """Return {subject, email, nickname} from a valid Kakao access token. Raises 401 otherwise."""
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(
            _KAKAO_ME, headers={"Authorization": f"Bearer {access_token}"}
        )
    if resp.status_code != 200:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "kakao token invalid")

    data = resp.json()
    account = data.get("kakao_account", {})
    profile = account.get("profile", {})
    return {
        "subject": str(data["id"]),
        "email": account.get("email"),
        "nickname": profile.get("nickname"),
    }
