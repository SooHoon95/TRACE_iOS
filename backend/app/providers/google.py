"""Verify a Google Sign-In `id_token` against Google's JWKS.

The iOS app runs the native Google flow (GoogleSignIn-iOS) and posts the resulting
`idToken` (a JWT) to `/auth/oauth`; we validate its signature, issuer and audience here.
"""
import jwt
from fastapi import HTTPException, status
from jwt import PyJWKClient

from ..config import get_settings

settings = get_settings()

_GOOGLE_ISSUERS = {"https://accounts.google.com", "accounts.google.com"}
_GOOGLE_JWKS = "https://www.googleapis.com/oauth2/v3/certs"
_jwk_client = PyJWKClient(_GOOGLE_JWKS)


def verify_google(id_token: str) -> dict:
    """Return {subject, email, nickname} from a verified Google id_token. Raises 401 if invalid."""
    try:
        signing_key = _jwk_client.get_signing_key_from_jwt(id_token)
        verify_aud = bool(settings.google_client_id)
        claims = jwt.decode(
            id_token,
            signing_key.key,
            algorithms=["RS256"],
            audience=settings.google_client_id or None,
            options={"verify_aud": verify_aud, "verify_iss": False},
        )
        if claims.get("iss") not in _GOOGLE_ISSUERS:
            raise ValueError(f"unexpected issuer {claims.get('iss')!r}")
        return {
            "subject": claims["sub"],
            "email": claims.get("email"),
            "nickname": claims.get("name"),
        }
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001 — surface any verification failure as 401
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, f"google token invalid: {exc}")
