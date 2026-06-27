"""Point the app at a throwaway SQLite DB + temp photo dir BEFORE app import."""
import os
import tempfile

_tmp = tempfile.mkdtemp(prefix="trace-test-")
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{_tmp}/test.db"
os.environ["STORAGE_BACKEND"] = "local"
os.environ["LOCAL_STORAGE_DIR"] = f"{_tmp}/photos"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["PUBLIC_BASE_URL"] = "http://test"
