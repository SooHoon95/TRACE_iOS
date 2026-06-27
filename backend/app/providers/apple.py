"""Verify a Sign in with Apple `id_token` against Apple's JWKS."""
import jwt
from fastapi import HTTPException, status
from jwt import PyJWKClient

from ..config import get_settings

settings = get_settings()

_APPLE_ISS = "https://appleid.apple.com"
_APPLE_JWKS = "https://appleid.apple.com/auth/keys"
_jwk_client = PyJWKClient(_APPLE_JWKS)


def verify_apple(id_token: str) -> dict:
    """Return {subject, email} from a verified Apple id_token. Raises 401 if invalid."""
    try:
        signing_key = _jwk_client.get_signing_key_from_jwt(id_token)
        verify_aud = bool(settings.apple_client_id)
        claims = jwt.decode(
            id_token,
            signing_key.key,
            algorithms=["RS256"],
            audience=settings.apple_client_id or None,
            issuer=_APPLE_ISS,
            options={"verify_aud": verify_aud},
        )
        return {"subject": claims["sub"], "email": claims.get("email")}
    except Exception as exc:  # noqa: BLE001 — surface any verification failure as 401
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, f"apple token invalid: {exc}")
