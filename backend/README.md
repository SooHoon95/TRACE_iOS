# TRACE API (backend)

Self-hosted backend for the TRACE iOS app. **FastAPI + SQLAlchemy(async)**, DB-agnostic
so it runs on **SQLite locally** (zero infra) and **Postgres in production** (OCI). Photos go to
local disk in dev and **OCI Object Storage** in prod. Endpoints mirror the iOS
`TraceStore` / `AuthService` / `PhotoStore` protocols 1:1.

> Replaces Supabase. Nothing here depends on a managed cloud — you run it yourself.

## Local development (no Docker)

```bash
cd backend
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env            # defaults to SQLite + local photo storage
uvicorn app.main:app --reload   # http://localhost:8000  (Swagger: /docs)
```

Run the tests (SQLite, in-memory app, full core-loop e2e):

```bash
pytest -q
```

## API surface

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET`  | `/health` | – | liveness |
| `POST` | `/auth/guest` | – | anonymous session → JWT |
| `POST` | `/auth/oauth` | – | Apple/Kakao token exchange → JWT |
| `GET`  | `/auth/me` | Bearer | current user |
| `GET`  | `/places` | – | all places (with aggregates) |
| `GET`  | `/places/nearby?lat&lng&radius_m` | – | places within radius |
| `POST` | `/places/resolve` | Bearer | snap-to-nearest-or-create (atomic) |
| `GET`  | `/places/{id}` | – | place detail |
| `GET`  | `/places/{id}/moments` | Bearer | exhibition (public + own private), newest first |
| `GET`  | `/moments/feed?limit` | – | recent public moments (home feed) |
| `POST` | `/moments` | Bearer | leave a moment (claim) |
| `GET`  | `/me/moments` | Bearer | my moments (도감) |
| `POST` | `/moments/{id}/report` | Bearer | report |
| `POST` | `/moments/{id}/hide` | Bearer | hide (author only) |
| `POST` | `/photos` | Bearer | upload a photo → `{ref,url}` |
| `GET`  | `/photos/{ref}` | – | serve photo (local backend only) |

Auth is a Bearer JWT (HS256) issued by `/auth/guest` or `/auth/oauth`. The iOS client
verifies Apple/Kakao on-device, then posts the provider token to `/auth/oauth`.

## Deploy to OCI (Always Free)

Target: one **Ampere A1 (Arm) "Always Free"** compute instance + **Object Storage** for photos.

1. **Provision** an Ampere A1 instance (Ubuntu 22.04). In its VCN security list, allow
   ingress on `80`/`443` (and `8000` if testing without a proxy).
2. **Install Docker** on the instance:
   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER && newgrp docker
   ```
3. **Copy this `backend/` dir** to the instance (`scp -r backend ubuntu@<ip>:~/`).
4. **Object Storage bucket** for photos:
   - Console → Storage → Buckets → create `moment-photos` (public read for the PoC).
   - Put an OCI API config at `~/.oci/config` on the instance (or use instance principals).
5. **Configure & run**:
   ```bash
   cd backend
   export JWT_SECRET=$(openssl rand -hex 32)
   export STORAGE_BACKEND=oci OCI_NAMESPACE=<ns> OCI_REGION=<region> OCI_BUCKET=moment-photos
   export PUBLIC_BASE_URL=https://<your-domain>
   export APPLE_CLIENT_ID=com.efreedom.trace KAKAO_REST_API_KEY=<key>
   docker compose up -d --build      # FastAPI + Postgres
   ```
   The API listens on `:8000`. Put **Caddy/nginx** in front for TLS, e.g. a 2-line Caddyfile:
   `your-domain { reverse_proxy localhost:8000 }`.
6. Point the iOS app's `TRACE_API_BASE_URL` (in `XCConfigs/Sensitive.xcconfig`) at
   `https://<your-domain>`.

For photos, `STORAGE_BACKEND=oci` requires `oci` in the image — uncomment it in
`requirements.txt` before building, or keep `local` (volume-backed) for the PoC.

## Environment variables

See `.env.example`. Key ones: `DATABASE_URL`, `JWT_SECRET`, `STORAGE_BACKEND`
(`local`|`oci`), `PUBLIC_BASE_URL`, `APPLE_CLIENT_ID`, `KAKAO_REST_API_KEY`, and the
`OCI_*` group when storing photos in Object Storage.

## Layout

```
app/
  main.py          FastAPI app + lifespan (table create)
  config.py        Settings (env/.env)
  db.py            async engine/session
  models.py        Profile · Place · Moment · MomentReport
  schemas.py       request/response DTOs (map to iOS Domain)
  service.py       resolve-or-create, aggregates, serialization
  security.py      JWT issue + get_current_user
  storage.py       Local + OCI photo backends (PhotoStore parity)
  geo.py           haversine
  providers/       apple.py (JWKS) · kakao.py (/v2/user/me)
  routers/         auth · places · moments · photos
tests/             core-loop e2e (SQLite)
Dockerfile · docker-compose.yml   (OCI host)
```
