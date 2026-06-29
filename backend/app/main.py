"""TRACE API — FastAPI application entrypoint."""
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text

from .config import get_settings
from .db import engine, init_models
from .routers import auth, moments, photos, places

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_models()
    yield


app = FastAPI(title="TRACE API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def request_id_middleware(request: Request, call_next):
    """Tag every response with a correlation id (echo an inbound one) for log tracing."""
    request_id = request.headers.get("X-Request-ID") or uuid.uuid4().hex
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    """Never leak a stack trace / HTML page — always return consistent JSON."""
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "internal server error"},
    )


@app.get("/health", tags=["meta"])
async def health():
    """Liveness: the process is up. No dependencies checked — keep it cheap."""
    return {"status": "ok", "service": "trace-api"}


@app.get("/ready", tags=["meta"])
async def ready():
    """Readiness: the database is reachable. 503 lets a load balancer drain this node."""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"status": "unavailable", "db": "down"},
        )
    return {"status": "ready", "db": "up"}


app.include_router(auth.router)
app.include_router(places.router)
app.include_router(moments.router)
app.include_router(photos.router)
