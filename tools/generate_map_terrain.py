#!/usr/bin/env python3
"""Genera el terreno base del mapa (GDD v1.4 Â§10.1, contrato Fase 2 Â§2, D-026).

Salida: assets/art/map/terrain_base.png (4096x3072 px), estilo pergamino/acuarela
de Ã©poca: mar azul-tinta con retÃ­cula nÃ¡utica, tierra ocre con relieve sutil,
costas de tinta, rÃ­os y bosques/montaÃ±as indicativos. Prohibido satÃ©lite/fantasÃ­a.

Determinista: misma semilla + mismos datos => mismo PNG (se imprime SHA-256).
Fuente de tierra: `data/map_borders.json` (uniÃ³n de los anillos de 1337) cuando
exista; si no, una costa de respaldo aproximada incluida aquÃ­ (solo mientras
AG-1 entrega las fronteras). El script es reproducible y revisable.

Uso:
  python tools/generate_map_terrain.py
  python tools/generate_map_terrain.py --borders data/map_borders.json --out assets/art/map/terrain_base.png
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

W, H = 4096, 3072
SEED = 1337

# Paleta Â§10 (azul tinta / ocre pergamino / dorado / rojo grana).
SEA_DEEP = (30, 55, 82)
SEA = (38, 69, 99)
SEA_LIGHT = (55, 91, 121)
LAND = (201, 183, 142)
LAND_LIGHT = (218, 202, 164)
LAND_DARK = (170, 150, 108)
INK = (27, 42, 65)
INK_SOFT = (51, 69, 92)
FOREST = (74, 96, 63)
MOUNTAIN = (126, 112, 92)
RIVER = (62, 99, 124)
GOLD = (201, 162, 39)
PARCHMENT = (233, 218, 186)

# LÃ­mites geogrÃ¡ficos estilizados: lon -12..50, lat 58..28 (mundo jugable).
LON_MIN, LON_MAX = -12.0, 50.0
LAT_MIN, LAT_MAX = 28.0, 58.0


def lonlat_to_px(lon: float, lat: float) -> tuple[float, float]:
    x = (lon - LON_MIN) / (LON_MAX - LON_MIN) * W
    y = (LAT_MAX - lat) / (LAT_MAX - LAT_MIN) * H
    return x, y


def lonlat_poly(points: list[tuple[float, float]]):
    return [lonlat_to_px(lon, lat) for lon, lat in points]


# ---------------------------------------------------------------------------
# Costa de respaldo (solo si data/map_borders.json no existe todavÃ­a).
# ---------------------------------------------------------------------------
FALLBACK_OUTER = [
    (-9.6, 37.0), (-9.3, 39.0), (-8.9, 43.2), (-6.0, 43.7), (-1.8, 43.4),
    (-1.2, 46.0), (-4.6, 48.4), (-1.6, 49.5), (1.8, 51.0), (4.4, 53.0),
    (7.8, 53.8), (8.2, 57.2), (11.0, 58.5), (13.5, 56.0), (14.5, 54.5),
    (19.0, 54.6), (21.0, 56.0), (24.0, 57.5), (28.0, 59.2), (30.0, 60.0),
    (33.5, 60.2), (40.0, 58.0), (45.0, 55.0), (48.0, 52.0), (50.0, 49.0),
    (48.0, 46.0), (44.0, 45.0), (40.0, 44.0), (37.5, 41.0), (41.0, 41.2),
    (42.5, 39.0), (44.5, 37.0), (48.0, 34.0), (50.0, 31.0), (47.0, 29.4),
    (44.0, 29.0), (40.0, 28.6), (35.0, 28.2), (32.0, 28.6), (29.0, 30.0),
    (24.0, 31.0), (20.0, 31.0), (17.0, 30.5), (13.0, 32.2), (10.0, 33.2),
    (6.0, 33.6), (2.0, 35.0), (-2.0, 35.5), (-6.0, 35.8), (-9.6, 37.0),
]

FALLBACK_SEAS = [
    # MediterrÃ¡neo occidental + Tirreno
    [(-5.6, 36.0), (-1.0, 36.2), (3.0, 37.0), (7.5, 38.0), (10.0, 36.5),
     (12.0, 37.8), (15.0, 37.5), (17.0, 40.0), (15.0, 41.5), (12.0, 41.5),
     (10.5, 43.5), (8.0, 43.5), (5.0, 43.0), (3.0, 42.0), (0.0, 39.5),
     (-3.5, 37.5), (-5.6, 36.0)],
    # AdriÃ¡tico + JÃ³nico
    [(12.5, 45.5), (15.5, 44.0), (18.0, 41.5), (20.0, 39.5), (19.0, 37.5),
     (16.0, 38.5), (14.0, 40.5), (13.0, 42.5), (12.5, 45.5)],
    # Egeo + MÃ¡rmara
    [(22.5, 40.5), (24.5, 39.0), (26.5, 38.0), (27.5, 40.5), (26.5, 41.5),
     (24.0, 41.5), (22.5, 40.5)],
    # Mar Negro
    [(28.2, 41.2), (30.0, 42.0), (34.0, 42.0), (37.5, 41.5), (40.0, 42.5),
     (41.0, 44.0), (38.0, 46.0), (34.0, 46.2), (30.5, 45.5), (28.5, 44.0),
     (28.2, 41.2)],
    # BÃ¡ltico
    [(10.5, 54.5), (13.5, 55.2), (17.0, 56.5), (20.0, 57.8), (23.0, 59.2),
     (25.5, 60.2), (23.0, 61.0), (19.5, 60.6), (17.0, 58.5), (14.0, 56.5),
     (11.0, 55.5), (10.5, 54.5)],
    # Mar del Norte
    [(1.5, 51.2), (4.0, 52.2), (7.0, 53.5), (8.2, 55.5), (7.0, 57.5),
     (4.0, 58.0), (1.0, 56.5), (-1.0, 54.0), (0.0, 52.0), (1.5, 51.2)],
    # Canal de la Mancha
    [(-4.5, 48.8), (-2.0, 49.4), (0.5, 50.4), (2.0, 50.8), (1.0, 49.6),
     (-1.2, 49.0), (-4.5, 48.8)],
]

FALLBACK_ISLANDS = [
    [(-5.8, 50.0), (-3.0, 50.2), (-1.0, 50.8), (1.5, 51.2), (1.8, 52.8),
     (0.0, 53.5), (-1.5, 55.5), (-3.5, 58.5), (-5.5, 58.2), (-6.2, 56.0),
     (-5.0, 54.5), (-4.5, 53.0), (-5.8, 50.0)],
    [(-10.5, 51.6), (-8.5, 51.4), (-6.2, 52.2), (-6.0, 54.5), (-8.0, 55.3),
     (-10.0, 54.5), (-10.5, 51.6)],
    [(12.4, 37.5), (15.5, 38.2), (15.2, 36.7), (12.6, 37.3), (12.4, 37.5)],
    [(8.2, 41.2), (9.6, 41.0), (9.2, 39.2), (8.3, 38.9), (8.2, 41.2)],
    [(8.5, 43.0), (9.5, 43.0), (9.4, 41.4), (8.6, 41.5), (8.5, 43.0)],
    [(23.4, 35.6), (26.2, 35.3), (26.0, 34.9), (23.6, 35.1), (23.4, 35.6)],
    [(32.2, 35.1), (34.6, 35.7), (34.3, 34.6), (32.4, 34.5), (32.2, 35.1)],
]

RIVERS = [
    [(7.6, 47.5), (7.9, 49.0), (6.8, 50.6), (4.6, 51.9), (4.0, 53.0)],
    [(8.6, 47.9), (11.0, 48.4), (14.2, 48.2), (17.0, 48.0), (19.0, 47.4),
     (22.0, 45.4), (25.0, 45.0), (28.0, 45.0), (29.6, 45.3)],
    [(7.4, 44.9), (9.2, 45.1), (11.0, 45.0), (12.4, 44.9)],
    [(-3.6, 42.6), (-1.2, 41.8), (0.6, 41.0)],
    [(2.2, 46.6), (0.8, 47.4), (-1.2, 47.3), (-2.6, 47.2)],
    [(31.0, 30.1), (31.4, 28.6)],
    [(48.0, 47.0), (46.2, 50.0), (45.2, 53.0), (46.0, 56.0)],
    [(33.0, 46.0), (31.2, 48.2), (30.3, 51.0), (30.5, 54.0)],
    [(19.2, 50.0), (18.2, 52.0), (19.0, 54.0)],
    [(14.0, 50.5), (13.2, 52.0), (12.2, 53.6)],
    [(9.0, 44.5), (10.5, 44.8), (12.0, 45.0)],
]

# ClÃºsteres indicativos de relieve (lon, lat, tipo, radio_grados).
RELIEF_CLUSTERS = [
    (10.0, 46.5, "mountain", 3.2),   # Alpes
    (0.0, 42.6, "mountain", 2.4),    # Pirineos
    (24.0, 47.0, "mountain", 3.0),   # CÃ¡rpatos
    (21.5, 41.8, "mountain", 2.2),   # Balcanes
    (31.5, 39.5, "mountain", 3.0),   # Anatolia
    (43.0, 42.5, "mountain", 2.4),   # CÃ¡ucaso
    (-2.0, 32.5, "mountain", 2.8),   # Atlas
    (12.0, 62.0, "mountain", 2.8),   # Escandinavia
    (7.0, 48.6, "forest", 2.6),      # Selva Negra / Germania
    (14.0, 51.0, "forest", 2.8),     # Bohemia
    (35.0, 55.0, "forest", 4.0),     # Rusia
    (24.0, 58.0, "forest", 3.0),     # BÃ¡ltico
    (17.0, 44.8, "forest", 2.2),     # Balcanes interiores
]

SEA_LABELS = [
    ("MARE SEPTENTRIONALE", 0.26, 0.10),
    ("OCEANUS OCCIDENTALIS", 0.08, 0.42),
    ("MARE NOSTRUM", 0.42, 0.74),
    ("MARE BALTICUM", 0.44, 0.13),
    ("PONTUS EUXINUS", 0.66, 0.47),
]


def _clip_ring_to_box(ring, xmin, xmax, ymin, ymax):
    """Sutherland-Hodgman: recorta un anillo lon/lat a una caja."""
    def clip_edge(points, inside, intersect):
        if not points:
            return points
        output = []
        prev = points[-1]
        prev_inside = inside(prev)
        for cur in points:
            cur_inside = inside(cur)
            if cur_inside:
                if not prev_inside:
                    output.append(intersect(prev, cur))
                output.append(cur)
            elif prev_inside:
                output.append(intersect(prev, cur))
            prev = cur
            prev_inside = cur_inside
        return output

    def x_intersect(a, b, xvalue):
        t = (xvalue - a[0]) / (b[0] - a[0]) if b[0] != a[0] else 0.0
        return (xvalue, a[1] + t * (b[1] - a[1]))

    def y_intersect(a, b, yvalue):
        t = (yvalue - a[1]) / (b[1] - a[1]) if b[1] != a[1] else 0.0
        return (a[0] + t * (b[0] - a[0]), yvalue)

    pts = list(ring)
    pts = clip_edge(pts, lambda p: p[0] >= xmin, lambda a, b: x_intersect(a, b, xmin))
    pts = clip_edge(pts, lambda p: p[0] <= xmax, lambda a, b: x_intersect(a, b, xmax))
    pts = clip_edge(pts, lambda p: p[1] >= ymin, lambda a, b: y_intersect(a, b, ymin))
    pts = clip_edge(pts, lambda p: p[1] <= ymax, lambda a, b: y_intersect(a, b, ymax))
    return pts


def _draw_geojson_land(draw, geojson_path: Path, scale: int) -> int:
    """Rasteriza la capa 'land' de Natural Earth (fallback temporal si AG-1 aun
    no ha entregado map_borders.json; los geojson son datos abiertos de AG-1)."""
    try:
        data = json.loads(geojson_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"[terrain] aviso: no se pudo leer {geojson_path.name}: {exc}")
        return 0
    clip = (-30.0, 70.0, 8.0, 75.0)  # lon_min, lon_max, lat_min, lat_max
    drawn = 0
    for feature in data.get("features", []):
        geometry = feature.get("geometry") or {}
        geom_type = geometry.get("type")
        coordinates = geometry.get("coordinates") or []
        polygons = []
        if geom_type == "Polygon":
            polygons = [coordinates]
        elif geom_type == "MultiPolygon":
            polygons = coordinates
        for polygon in polygons:
            if not polygon:
                continue
            outer = polygon[0]
            if len(outer) < 3:
                continue
            lons = [float(p[0]) for p in outer]
            lats = [float(p[1]) for p in outer]
            if max(lons) < clip[0] or min(lons) > clip[1] or max(lats) < clip[2] or min(lats) > clip[3]:
                continue
            clipped = _clip_ring_to_box(outer, clip[0], clip[1], clip[2], clip[3])
            if len(clipped) < 3:
                continue
            points = []
            for lon, lat in clipped:
                x, y = lonlat_to_px(lon, lat)
                points.append((x * scale, y * scale))
            draw.polygon(points, fill=255)
            drawn += 1
    return drawn


def build_land_mask(borders_path: Path | None, land_geojson: Path | None = None) -> Image.Image:
    """Mascara L (255=tierra) a 2x y reducida con antialias.

    Orden de fuentes: map_borders.json (D-026) -> Natural Earth land (fallback
    temporal mientras AG-1 entrega) -> costa de respaldo incluida.
    """
    scale = 2
    mask = Image.new("L", (W * scale, H * scale), 0)
    draw = ImageDraw.Draw(mask)
    if borders_path is not None and borders_path.exists():
        data = json.loads(borders_path.read_text(encoding="utf-8"))
        years = data.get("years", {})
        entries = years.get("1337") or (next(iter(years.values()), []) if years else [])
        for entry in entries:
            ring = entry.get("ring") or []
            if len(ring) < 3:
                continue
            pts = [(float(p[0]) * W * scale, float(p[1]) * H * scale) for p in ring if len(p) >= 2]
            if len(pts) >= 3:
                draw.polygon(pts, fill=255)
        source = "map_borders.json (%d regiones)" % len(entries)
    elif land_geojson is not None and land_geojson.exists():
        drawn = _draw_geojson_land(draw, land_geojson, scale)
        source = "Natural Earth land (fallback temporal: %s, %d poligonos)" % (land_geojson.name, drawn)
    else:
        draw.polygon([(x * scale, y * scale) for x, y in lonlat_poly(FALLBACK_OUTER)], fill=255)
        for sea in FALLBACK_SEAS:
            draw.polygon([(x * scale, y * scale) for x, y in lonlat_poly(sea)], fill=0)
        for island in FALLBACK_ISLANDS:
            draw.polygon([(x * scale, y * scale) for x, y in lonlat_poly(island)], fill=255)
        source = "costa de respaldo (map_borders.json aun no existe)"
    mask = mask.resize((W, H), Image.LANCZOS)
    mask = mask.filter(ImageFilter.GaussianBlur(2.0))
    mask = mask.point(lambda v: 255 if v >= 128 else 0)
    print(f"[terrain] tierra: {source}")
    return mask


def build_sea(rng: np.random.Generator) -> Image.Image:
    base = Image.new("RGB", (W, H), SEA)
    px = np.zeros((H, W, 3), dtype=np.float32)
    px[:, :, 0] = SEA[0]
    px[:, :, 1] = SEA[1]
    px[:, :, 2] = SEA[2]
    # Gradiente norte-sur y manchas de acuarela.
    yy = np.linspace(0.0, 1.0, H, dtype=np.float32)[:, None]
    px[:, :, 0] += (yy - 0.4) * 10.0
    px[:, :, 2] += (0.4 - yy) * 16.0
    low = rng.normal(0.0, 1.0, (192, 256)).astype(np.float32)
    low = np.asarray(Image.fromarray(((low - low.min()) / (np.ptp(low) + 1e-6) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC), dtype=np.float32)
    px += (low[:, :, None] - 128.0) * 0.035
    image = Image.fromarray(np.clip(px, 0, 255).astype(np.uint8), "RGB")
    draw = ImageDraw.Draw(image, "RGBA")
    # RetÃ­cula nÃ¡utica.
    for i in range(1, 13):
        x = W * i / 12.0
        draw.line([(x, 0), (x, H)], fill=(*GOLD, 14), width=2)
    for j in range(1, 9):
        y = H * j / 8.0
        draw.line([(0, y), (W, y)], fill=(*GOLD, 14), width=2)
    # Manchas grandes de aguada.
    for _ in range(30):
        cx, cy = rng.uniform(0, W), rng.uniform(0, H)
        rx, ry = rng.uniform(W * 0.03, W * 0.14), rng.uniform(H * 0.03, H * 0.12)
        color = SEA_LIGHT if rng.random() < 0.5 else SEA_DEEP
        draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(*color, rng.integers(8, 22)))
    return image


def build_land(mask: Image.Image, rng: np.random.Generator) -> Image.Image:
    base = np.zeros((H, W, 3), dtype=np.float32)
    base[:, :, 0] = LAND[0]
    base[:, :, 1] = LAND[1]
    base[:, :, 2] = LAND[2]
    # Relieve sutil: ruido de baja frecuencia + sombreado.
    noise = rng.normal(0.0, 1.0, (96, 128)).astype(np.float32)
    noise = (noise - noise.min()) / (np.ptp(noise) + 1e-6)
    noise_big = np.asarray(Image.fromarray((noise * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC), dtype=np.float32) / 255.0
    height = Image.fromarray((noise_big * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(14))
    height_np = np.asarray(height, dtype=np.float32) / 255.0
    # Sombreado direccional (luz noroeste) para relieve.
    gy, gx = np.gradient(height_np)
    shade = np.clip(0.5 + (gx * 1.6 - gy * 1.2) * 8.0, 0.0, 1.0)
    tint = height_np[:, :, None]
    base = base * (0.88 + 0.16 * tint)
    base = base * (0.90 + 0.16 * shade[:, :, None])
    dry = np.clip((1.0 - height_np) * 0.5, 0.0, 0.4)
    base = base * (1.0 - dry[:, :, None]) + np.array(LAND_LIGHT, dtype=np.float32) * dry[:, :, None]
    land = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB")
    # Textura de papel: grano fino.
    grain = rng.integers(0, 255, (H // 3, W // 3), dtype=np.uint8)
    grain = np.asarray(Image.fromarray(grain).resize((W, H), Image.NEAREST), dtype=np.int16) - 128
    land_np = np.asarray(land, dtype=np.int16)
    land_np = np.clip(land_np + (grain[:, :, None] * 0.045), 0, 255).astype(np.uint8)
    return Image.fromarray(land_np, "RGB")


def draw_coast(image: Image.Image, mask: Image.Image) -> None:
    # LÃ­nea de tinta: borde de la mÃ¡scara (tierra) + halo exterior.
    eroded = mask.filter(ImageFilter.MinFilter(7))
    coast_land = ImageChops.subtract(mask, eroded)
    coast_land = coast_land.filter(ImageFilter.MaxFilter(5))
    coast_img = Image.new("RGBA", (W, H), (*INK, 0))
    coast_img.putalpha(coast_land.point(lambda v: int(v * 0.92)))
    image.paste(coast_img, (0, 0), coast_img)
    # Halo exterior tenue (aguada oscura junto a la costa).
    dilated = mask.filter(ImageFilter.MaxFilter(9))
    outer = ImageChops.subtract(dilated, mask).filter(ImageFilter.GaussianBlur(3))
    outer_img = Image.new("RGBA", (W, H), (*INK, 0))
    outer_img.putalpha(outer.point(lambda v: int(v * 0.22)))
    image.paste(outer_img, (0, 0), outer_img)


def draw_sea_labels(image: Image.Image) -> None:
    try:
        from PIL import ImageFont
        font = None
        for name in ("georgia.ttf", "times.ttf", "DejaVuSerif.ttf", "C:/Windows/Fonts/georgia.ttf"):
            try:
                font = ImageFont.truetype(name, 34)
                break
            except OSError:
                continue
        if font is None:
            font = ImageFont.load_default()
        draw = ImageDraw.Draw(image, "RGBA")
        for text, fx, fy in SEA_LABELS:
            draw.text((int(W * fx), int(H * fy)), text, font=font, fill=(*PARCHMENT, 42))
    except Exception as exc:  # pragma: no cover - fuente opcional
        print(f"[terrain] aviso: etiquetas de mar omitidas ({exc})")


def draw_rivers(image: Image.Image, mask: Image.Image) -> None:
    river = Image.new("RGBA", (W, H), (*RIVER, 0))
    draw = ImageDraw.Draw(river)
    for line in RIVERS:
        pts = lonlat_poly(line)
        draw.line(pts, fill=(*RIVER, 190), width=5, joint="curve")
        for p in pts:
            draw.ellipse([p[0] - 2.5, p[1] - 2.5, p[0] + 2.5, p[1] + 2.5], fill=(*RIVER, 170))
    river.putalpha(ImageChops.multiply(river.getchannel("A"), mask))
    image.paste(river, (0, 0), river)


def draw_relief_icons(image: Image.Image, mask: Image.Image, rng: np.random.Generator) -> None:
    icons = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icons)
    mask_np = np.asarray(mask, dtype=np.uint8)

    def on_land(x: int, y: int) -> bool:
        if 0 <= x < W and 0 <= y < H:
            return mask_np[y, x] > 128
        return False

    for lon, lat, kind, radius_deg in RELIEF_CLUSTERS:
        cx, cy = lonlat_to_px(lon, lat)
        px_per_deg = W / (LON_MAX - LON_MIN)
        radius = radius_deg * px_per_deg
        count = max(6, int(radius / 16))
        for _ in range(count):
            angle = rng.uniform(0, math.tau)
            distance = math.sqrt(rng.uniform(0, 1)) * radius
            x = int(cx + math.cos(angle) * distance)
            y = int(cy + math.sin(angle) * distance * 0.8)
            if not on_land(x, y):
                continue
            size = rng.uniform(7.0, 15.0)
            if kind == "mountain":
                draw.line([(x - size, y + size * 0.7), (x, y - size * 0.8), (x + size, y + size * 0.7)], fill=(*MOUNTAIN, 150), width=2)
                draw.line([(x - size * 0.25, y - size * 0.15), (x, y - size * 0.8)], fill=(*PARCHMENT, 90), width=1)
            else:
                draw.line([(x, y + size * 0.6), (x, y - size * 0.2)], fill=(*INK_SOFT, 120), width=2)
                draw.polygon([(x - size * 0.55, y + size * 0.4), (x, y - size * 1.1), (x + size * 0.55, y + size * 0.4)], fill=(*FOREST, 120))
                draw.polygon([(x - size * 0.4, y + size * 0.1), (x, y - size * 0.75), (x + size * 0.4, y + size * 0.1)], fill=(*FOREST, 90))
    icons.putalpha(ImageChops.multiply(icons.getchannel("A"), mask))
    image.paste(icons, (0, 0), icons)


def add_parchment_finish(image: Image.Image, rng: np.random.Generator) -> Image.Image:
    # Tono pergamino general y viÃ±eta.
    overlay = Image.new("RGBA", (W, H), (*PARCHMENT, 26))
    image = Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")
    yy = np.linspace(-1.0, 1.0, H, dtype=np.float32)[:, None]
    xx = np.linspace(-1.0, 1.0, W, dtype=np.float32)[None, :]
    vignette = np.clip(1.0 - 0.20 * (xx ** 2 + yy ** 2), 0.55, 1.0)
    arr = np.asarray(image, dtype=np.float32) * vignette[:, :, None]
    # Manchas de acuarela / humedad.
    stains = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stains)
    for _ in range(22):
        cx, cy = rng.uniform(0, W), rng.uniform(0, H)
        r = rng.uniform(W * 0.02, W * 0.10)
        color = (120, 90, 44) if rng.random() < 0.6 else (70, 84, 92)
        sd.ellipse([cx - r, cy - r * 0.7, cx + r, cy + r * 0.7], fill=(*color, int(rng.integers(3, 10))))
    stains = stains.filter(ImageFilter.GaussianBlur(22))
    base = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    base = Image.alpha_composite(base, stains)
    return base.convert("RGB")


def add_map_frame(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    # Marco de atlas: doble filete y esquinas.
    draw.rectangle([10, 10, W - 10, H - 10], outline=(*INK, 150), width=3)
    draw.rectangle([22, 22, W - 22, H - 22], outline=(*GOLD, 90), width=2)
    draw.rectangle([30, 30, W - 30, H - 30], outline=(*PARCHMENT, 60), width=1)
    for x, y in ((34, 34), (W - 34, 34), (34, H - 34), (W - 34, H - 34)):
        draw.ellipse([x - 8, y - 8, x + 8, y + 8], fill=(*GOLD, 110))
    # Escala de leguas decorativa.
    ox, oy = W - 420, H - 70
    for i in range(6):
        x0 = ox + i * 56
        fill = (*PARCHMENT, 90) if i % 2 == 0 else (0, 0, 0, 0)
        draw.rectangle([x0, oy, x0 + 56, oy + 10], fill=fill, outline=(*INK, 130), width=2)
    draw.text((ox, oy + 18), "LEGUAS", fill=(*INK, 120)) if False else None


def main() -> int:
    parser = argparse.ArgumentParser(description="Genera terrain_base.png determinista (4096x3072).")
    parser.add_argument("--borders", default="data/map_borders.json", help="ruta a map_borders.json (opcional)")
    parser.add_argument("--out", default="assets/art/map/terrain_base.png", help="PNG de salida")
    parser.add_argument("--seed", type=int, default=SEED)
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    borders_path = root / args.borders
    out_path = root / args.out
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # Fallback temporal de costa mientras AG-1 entrega map_borders.json: los
    # geojson de Natural Earth (dominio publico) que AG-1 usa como referencia.
    land_geojson = None
    for candidate in ("data/_ne_ne_50m_land.geojson", "data/_ne_ne_110m_land.geojson"):
        candidate_path = root / candidate
        if candidate_path.exists():
            land_geojson = candidate_path
            break

    rng = np.random.default_rng(args.seed)
    print(f"[terrain] generando {W}x{H} seed={args.seed} ...")
    mask = build_land_mask(borders_path if borders_path.exists() else None, land_geojson)
    image = build_sea(rng)
    land = build_land(mask, rng)
    image.paste(land, (0, 0), mask)
    draw_coast(image, mask)
    draw_rivers(image, mask)
    draw_relief_icons(image, mask, rng)
    # Las etiquetas de mar pertenecen a la capa de entidades (crisp al hacer zoom).
    image = add_parchment_finish(image, rng)
    add_map_frame(image)

    # Cuantiza a paleta para mantener el PNG por debajo de 8 MB.
    quantized = image.quantize(colors=160, method=Image.MEDIANCUT, dither=Image.FLOYDSTEINBERG)
    quantized.save(out_path, format="PNG", optimize=True, compress_level=9)
    size = out_path.stat().st_size
    digest = hashlib.sha256(out_path.read_bytes()).hexdigest()
    print(f"[terrain] escrito {out_path} ({size / 1024 / 1024:.2f} MiB) sha256={digest}")
    if size > 8 * 1024 * 1024:
        print("[terrain] ERROR: PNG > 8 MB (criterio Â§10.1)")
        return 2
    if size > 150 * 1024:
        pass  # el lÃ­mite de 150 KB es solo para map_borders.json
    return 0


if __name__ == "__main__":
    sys.exit(main())
