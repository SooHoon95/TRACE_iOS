"""Runtime settings, loaded from environment / .env (12-factor)."""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    # Core
    database_url: str = "sqlite+aiosqlite:///./trace.db"
    jwt_secret: str = "dev-insecure-change-me"
    jwt_alg: str = "HS256"
    jwt_expire_hours: int = 24 * 30  # 30 days
    cors_origins: str = "*"
    # Moderation: auto-hide a moment once this many DISTINCT users report it (T2.11).
    report_hide_threshold: int = 3
    # Rate limiting: max mutating requests per client IP, per path, per minute (0 = off).
    rate_limit_per_minute: int = 120

    # Auth providers (verification still checks signature/issuer when these are blank)
    apple_client_id: str = ""  # expected `aud` of the Apple id_token
    kakao_rest_api_key: str = ""
    google_client_id: str = ""  # expected `aud` of the Google id_token

    # Photo storage: "local" | "oci"
    storage_backend: str = "local"
    local_storage_dir: str = "./_photos"
    public_base_url: str = "http://localhost:8000"

    # OCI Object Storage (storage_backend == "oci")
    oci_namespace: str = ""
    oci_bucket: str = "moment-photos"
    oci_region: str = ""
    oci_config_file: str = "~/.oci/config"
    oci_config_profile: str = "DEFAULT"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
