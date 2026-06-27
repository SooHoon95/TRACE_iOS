"""End-to-end core loop against the real ASGI app (SQLite + local photo storage)."""
from fastapi.testclient import TestClient

from app.main import app

_JPEG = b"\xff\xd8\xff\xe0demo"


def _guest(client: TestClient, nickname: str = "여행자") -> dict:
    r = client.post("/auth/guest", json={"nickname": nickname})
    assert r.status_code == 200, r.text
    tok = r.json()["access_token"]
    return {"Authorization": f"Bearer {tok}"}


def _upload(client: TestClient, headers: dict) -> str:
    r = client.post(
        "/photos", headers=headers, files={"file": ("p.jpg", _JPEG, "image/jpeg")}
    )
    assert r.status_code == 201, r.text
    return r.json()["ref"]


def test_core_loop_reflects_across_surfaces():
    with TestClient(app) as client:
        assert client.get("/health").json()["status"] == "ok"

        h = _guest(client, "지민")
        place = client.post(
            "/places/resolve",
            headers=h,
            json={"latitude": 33.458, "longitude": 126.942, "radius_m": 20, "name": "성산일출봉"},
        ).json()
        pid = place["id"]

        ref = _upload(client, h)
        created = client.post(
            "/moments",
            headers=h,
            json={
                "place_id": pid,
                "photo_ref": ref,
                "latitude": 33.458,
                "longitude": 126.942,
                "caption": "첫 순간",
                "vibe": "calm",
                "visibility": "publicExhibit",
            },
        )
        assert created.status_code == 201, created.text
        mid = created.json()["id"]
        assert created.json()["photo_url"].endswith(ref)

        # shows in the home feed
        feed = client.get("/moments/feed").json()
        assert any(m["id"] == mid for m in feed)

        # shows in the place exhibition
        exhibit = client.get(f"/places/{pid}/moments", headers=h).json()
        assert any(m["id"] == mid for m in exhibit)

        # aggregates recomputed
        detail = client.get(f"/places/{pid}").json()
        assert detail["moment_count"] == 1
        assert detail["contributor_count"] == 1
        assert detail["cover_photo_ref"] == ref

        # resolve again within radius snaps to the SAME place (no duplicate)
        again = client.post(
            "/places/resolve",
            headers=h,
            json={"latitude": 33.4580005, "longitude": 126.9420005, "name": "성산일출봉"},
        ).json()
        assert again["id"] == pid


def test_private_moment_stays_out_of_public_surfaces():
    with TestClient(app) as client:
        author = _guest(client, "작성자")
        place = client.post(
            "/places/resolve",
            headers=author,
            json={"latitude": 33.5, "longitude": 126.5, "name": "비밀자리"},
        ).json()
        pid = place["id"]
        ref = _upload(client, author)
        priv = client.post(
            "/moments",
            headers=author,
            json={
                "place_id": pid,
                "photo_ref": ref,
                "latitude": 33.5,
                "longitude": 126.5,
                "visibility": "privateOnly",
            },
        ).json()
        mid = priv["id"]

        # absent from the public feed
        feed = client.get("/moments/feed").json()
        assert all(m["id"] != mid for m in feed)

        # another viewer's exhibition view does NOT include it
        other = _guest(client, "구경꾼")
        other_view = client.get(f"/places/{pid}/moments", headers=other).json()
        assert all(m["id"] != mid for m in other_view)

        # the author's own exhibition view DOES include it
        own_view = client.get(f"/places/{pid}/moments", headers=author).json()
        assert any(m["id"] == mid for m in own_view)

        # public place aggregates exclude the private moment
        detail = client.get(f"/places/{pid}").json()
        assert detail["moment_count"] == 0


def test_moment_auto_hidden_after_threshold_reports():
    with TestClient(app) as client:
        author = _guest(client, "작성자")
        place = client.post(
            "/places/resolve", headers=author,
            json={"latitude": 35.1, "longitude": 129.0, "name": "신고터"},
        ).json()
        ref = _upload(client, author)
        mid = client.post(
            "/moments", headers=author,
            json={"place_id": place["id"], "photo_ref": ref, "latitude": 35.1, "longitude": 129.0},
        ).json()["id"]

        # Two distinct reports → still visible (threshold is 3).
        for i in range(2):
            reporter = _guest(client, f"신고자{i}")
            assert client.post(f"/moments/{mid}/report", headers=reporter,
                               json={"reason": "spam"}).status_code == 204
        assert any(m["id"] == mid for m in client.get("/moments/feed").json())

        # Third distinct reporter crosses the threshold → auto-hidden.
        third = _guest(client, "신고자3")
        assert client.post(f"/moments/{mid}/report", headers=third,
                           json={"reason": "spam"}).status_code == 204
        assert all(m["id"] != mid for m in client.get("/moments/feed").json())


def test_repeated_reports_by_one_user_do_not_auto_hide():
    with TestClient(app) as client:
        author = _guest(client, "작성자2")
        place = client.post(
            "/places/resolve", headers=author,
            json={"latitude": 36.0, "longitude": 127.5, "name": "단일신고터"},
        ).json()
        ref = _upload(client, author)
        mid = client.post(
            "/moments", headers=author,
            json={"place_id": place["id"], "photo_ref": ref, "latitude": 36.0, "longitude": 127.5},
        ).json()["id"]

        spammer = _guest(client, "도배신고")
        for _ in range(5):
            client.post(f"/moments/{mid}/report", headers=spammer, json={"reason": "spam"})
        # DISTINCT reporters = 1 → not auto-hidden.
        assert any(m["id"] == mid for m in client.get("/moments/feed").json())


def test_hide_is_author_only():
    with TestClient(app) as client:
        author = _guest(client, "주인")
        place = client.post(
            "/places/resolve", headers=author, json={"latitude": 34.0, "longitude": 127.0, "name": "Z"}
        ).json()
        ref = _upload(client, author)
        mid = client.post(
            "/moments",
            headers=author,
            json={"place_id": place["id"], "photo_ref": ref, "latitude": 34.0, "longitude": 127.0},
        ).json()["id"]

        stranger = _guest(client, "남")
        assert client.post(f"/moments/{mid}/hide", headers=stranger).status_code == 403
        assert client.post(f"/moments/{mid}/report", headers=stranger, json={"reason": "spam"}).status_code == 204
        assert client.post(f"/moments/{mid}/hide", headers=author).status_code == 204

        # hidden moment drops out of the feed
        feed = client.get("/moments/feed").json()
        assert all(m["id"] != mid for m in feed)
