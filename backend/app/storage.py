"""Photo storage abstraction. Local disk for dev; OCI Object Storage for prod.

The iOS `PhotoStore` protocol maps here: `upload(data, key) -> ref` and `url(ref)`.
Swapping backends is config-only (STORAGE_BACKEND), so no app code changes for OCI.
"""
import os
from pathlib import Path

from .config import get_settings

settings = get_settings()


class PhotoStorage:
    async def save(self, data: bytes, ref: str, content_type: str = "image/jpeg") -> str:
        raise NotImplementedError

    def url(self, ref: str) -> str | None:
        raise NotImplementedError

    def read(self, ref: str) -> bytes | None:
        return None


class LocalPhotoStorage(PhotoStorage):
    """Saves under LOCAL_STORAGE_DIR; served back via the /photos/{ref} route."""

    def __init__(self) -> None:
        self.dir = Path(settings.local_storage_dir)
        self.dir.mkdir(parents=True, exist_ok=True)

    async def save(self, data: bytes, ref: str, content_type: str = "image/jpeg") -> str:
        path = self.dir / ref
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return ref

    def url(self, ref: str) -> str | None:
        return f"{settings.public_base_url.rstrip('/')}/photos/{ref}"

    def read(self, ref: str) -> bytes | None:
        path = self.dir / ref
        return path.read_bytes() if path.exists() else None


class OCIPhotoStorage(PhotoStorage):
    """Oracle Cloud Object Storage. `oci` SDK imported lazily so local dev needn't install it."""

    def __init__(self) -> None:
        import oci  # lazy import

        cfg = oci.config.from_file(
            os.path.expanduser(settings.oci_config_file), settings.oci_config_profile
        )
        self._oci = oci
        self.client = oci.object_storage.ObjectStorageClient(cfg)
        self.namespace = settings.oci_namespace or self.client.get_namespace().data
        self.bucket = settings.oci_bucket
        self.region = settings.oci_region or cfg.get("region", "")

    async def save(self, data: bytes, ref: str, content_type: str = "image/jpeg") -> str:
        # put_object is blocking; acceptable for PoC throughput.
        self.client.put_object(
            self.namespace, self.bucket, ref, data, content_type=content_type
        )
        return ref

    def url(self, ref: str) -> str | None:
        return (
            f"https://objectstorage.{self.region}.oraclecloud.com"
            f"/n/{self.namespace}/b/{self.bucket}/o/{ref}"
        )


def _build_storage() -> PhotoStorage:
    if settings.storage_backend == "oci":
        return OCIPhotoStorage()
    return LocalPhotoStorage()


storage: PhotoStorage = _build_storage()
