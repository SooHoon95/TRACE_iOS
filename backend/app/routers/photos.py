"""Photo upload + (local backend) serving."""
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import Response

from .. import models, schemas
from ..security import get_current_user
from ..storage import LocalPhotoStorage, storage

router = APIRouter(prefix="/photos", tags=["photos"])


@router.post("", response_model=schemas.PhotoOut, status_code=status.HTTP_201_CREATED)
async def upload_photo(
    file: UploadFile = File(...),
    user: models.Profile = Depends(get_current_user),
):
    data = await file.read()
    ref = f"{user.id}/{uuid4().hex}.jpg"
    await storage.save(data, ref, content_type=file.content_type or "image/jpeg")
    return schemas.PhotoOut(ref=ref, url=storage.url(ref))


@router.get("/{ref:path}")
async def get_photo(ref: str):
    if not isinstance(storage, LocalPhotoStorage):
        # OCI is served directly from Object Storage URLs.
        raise HTTPException(status.HTTP_404_NOT_FOUND, "not served here")
    data = storage.read(ref)
    if data is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "photo not found")
    return Response(content=data, media_type="image/jpeg")
