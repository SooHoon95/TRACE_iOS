"""Geo helpers — haversine distance in meters."""
import math

EARTH_RADIUS_M = 6_371_000.0
DEFAULT_SNAP_RADIUS_M = 20.0  # mirrors Domain.GeoMath.defaultSnapRadiusMeters


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return EARTH_RADIUS_M * 2 * math.asin(math.sqrt(a))
