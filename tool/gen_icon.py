#!/usr/bin/env python3
"""Иконки Wickly из одной геометрии: «Огонёк».

Знак — язык пламени с вычтенным ядром. Симметричная капля читалась бы водой,
поэтому вершина уведена вбок, а левый бок поджат: острие, наклон и перегиб —
три признака, по которым огонь узнают.

Геометрия живёт ТОЛЬКО здесь и в `docs/logo.md`. Пропорции держит одна пара
чисел: `FG_SCALE` (доля высоты знака от 108dp adaptive-холста) и выведенный из
неё `LEGACY_SCALE = FG_SCALE * 108 / 72`. Так legacy-PNG и adaptive-иконка дают
ОДИН видимый размер. Менять их можно только вместе.

Запуск:  python3 tool/gen_icon.py [--tint amber|ember|cream]
Нужен cairosvg:  pip install --user cairosvg pillow
"""
from __future__ import annotations

import argparse
import io
import math
import sys
from pathlib import Path

try:
    import cairosvg
    from PIL import Image
except ImportError:  # pragma: no cover — подсказка, а не логика
    sys.exit("Нужны cairosvg и pillow: pip install --user cairosvg pillow")

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"

# ── Геометрия знака (поле 100×100) ──────────────────────────────────────────

OUTER = dict(cx=50, top=8, w=26, bottom=92, lean=0.16, waist=0.30)
CORE = dict(cx=50, top=46, w=11, bottom=86, lean=0.22, waist=0.32)

# Габарит знака в единицах поля: ширина 52, высота 84 — отсюда считается посадка.
MARK_H = OUTER["bottom"] - OUTER["top"]
MARK_W = OUTER["w"] * 2

# Доля высоты знака от 108dp. При 0.45 знак занимает две трети видимого поля
# (48.6 из 72dp) — плотность, на которой иконка не распирает маску, а его
# габарит с запасом ложится в safe zone ⌀66dp.
FG_SCALE = 0.45
LEGACY_SCALE = FG_SCALE * 108 / 72

# ── Колеровки ───────────────────────────────────────────────────────────────

TINTS = {
    # id: (фон, знак) — id уходит в имена ресурсов и в выбор иконки
    "ember": ("#1B1107", "#FFB964"),   # огонь во тьме: фирменный вечер
    "amber": ("#FFB964", "#1B1107"),   # уголь на амбре: максимальный контраст
    "cream": ("#FFF8F4", "#8A5200"),   # бумага: для светлых лаунчеров
}

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def flame(cx, top, w, bottom, lean=0.16, waist=0.30) -> str:
    """Язык пламени: вершина уведена вбок, левый бок с перегибом."""
    mid = bottom - w
    h = mid - top
    tip = cx + w * lean
    return (
        f"M{tip:.2f} {top:.2f} "
        f"C{cx + w * 0.92:.2f} {top + h * 0.30:.2f} "
        f"{cx + w:.2f} {mid - w * 0.55:.2f} {cx + w:.2f} {mid:.2f} "
        f"A{w:.2f} {w:.2f} 0 0 1 {cx - w:.2f} {mid:.2f} "
        f"C{cx - w:.2f} {mid - w * 0.62:.2f} "
        f"{cx - w * 0.82:.2f} {top + h * (waist + 0.16):.2f} "
        f"{cx - w * 0.10:.2f} {top + h * waist:.2f} "
        f"C{cx + w * 0.10:.2f} {top + h * (waist - 0.14):.2f} "
        f"{tip:.2f} {top + h * 0.10:.2f} {tip:.2f} {top:.2f} Z"
    )


def squircle(cx, cy, r, n=4.0, steps=160) -> str:
    """Суперэллипс — форма legacy-подложки, как у самих иконок Android."""
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        c, s = math.cos(t), math.sin(t)
        x = cx + r * math.copysign(abs(c) ** (2 / n), c)
        y = cy + r * math.copysign(abs(s) ** (2 / n), s)
        pts.append(f"{x:.2f} {y:.2f}")
    return "M" + " L".join(pts) + " Z"


def mark_path() -> str:
    """Знак одним путём: ядро вычитается правилом evenodd."""
    return f"{flame(**OUTER)} {flame(**CORE)}"


def mark_svg(size: int, color: str, height_ratio: float, bg: str | None = None,
             bg_shape: str | None = None) -> str:
    """Знак, вписанный по высоте в долю [height_ratio] от холста [size]."""
    scale = height_ratio * size / MARK_H
    # Центрируем габарит знака, а не поле 100×100.
    cx = (OUTER["top"] + OUTER["bottom"]) / 2
    tx = size / 2 - 50 * scale
    ty = size / 2 - cx * scale
    layers = []
    if bg:
        layers.append(f'<rect width="{size}" height="{size}" fill="{bg}"/>' if bg_shape is None
                      else f'<path d="{bg_shape}" fill="{bg}"/>')
    layers.append(
        f'<g transform="translate({tx:.3f} {ty:.3f}) scale({scale:.5f})">'
        f'<path fill-rule="evenodd" fill="{color}" d="{mark_path()}"/></g>'
    )
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
            f'viewBox="0 0 {size} {size}">{"".join(layers)}</svg>')


def png(svg: str, size: int) -> Image.Image:
    data = cairosvg.svg2png(bytestring=svg.encode(), output_width=size, output_height=size)
    return Image.open(io.BytesIO(data)).convert("RGBA")


def write(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(f"  {path.relative_to(ROOT)}  {image.width}×{image.height}")


def build(tint: str) -> None:
    bg, fg = TINTS[tint]
    print(f"Колеровка {tint}: фон {bg}, знак {fg}")

    for density, k in DENSITIES.items():
        # Legacy: подложка-суперэллипс со знаком внутри, 48dp базово.
        side = int(48 * k)
        shape = squircle(side / 2, side / 2, side * 0.5 * 0.94, n=4.0)
        legacy = png(mark_svg(side, fg, LEGACY_SCALE, bg=bg, bg_shape=shape), side)
        write(RES / f"mipmap-{density}/ic_launcher.png", legacy)

        # Adaptive: фон отдельным цветом, знак — прозрачный foreground 108dp.
        big = int(108 * k)
        write(RES / f"mipmap-{density}/ic_launcher_foreground.png",
              png(mark_svg(big, fg, FG_SCALE), big))
        # Тематическая иконка: систему интересует только силуэт.
        write(RES / f"mipmap-{density}/ic_launcher_monochrome.png",
              png(mark_svg(big, "#000000", FG_SCALE), big))

    (RES / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
        '</adaptive-icon>\n', encoding="utf-8")
    print("  res/mipmap-anydpi-v26/ic_launcher.xml")

    (RES / "values").mkdir(parents=True, exist_ok=True)
    (RES / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        f'    <color name="ic_launcher_background">{bg}</color>\n'
        '</resources>\n', encoding="utf-8")
    print("  res/values/ic_launcher_background.xml")

    # Веб-иконки Flutter. Maskable рисуется мельче: PWA-маска съедает край.
    shape512 = squircle(256, 256, 240, n=4.0)
    for name, size, ratio, shaped in (
        ("Icon-192", 192, LEGACY_SCALE, True),
        ("Icon-512", 512, LEGACY_SCALE, True),
        ("Icon-maskable-192", 192, FG_SCALE, False),
        ("Icon-maskable-512", 512, FG_SCALE, False),
    ):
        shape = squircle(size / 2, size / 2, size * 0.47, n=4.0) if shaped else None
        write(ROOT / f"web/icons/{name}.png",
              png(mark_svg(size, fg, ratio, bg=bg, bg_shape=shape), size))
    write(ROOT / "web/favicon.png", png(mark_svg(32, fg, LEGACY_SCALE, bg=bg), 32))

    # Исходник знака — для сайта, README и всего, что не Android.
    art = ROOT / "docs/logo"
    art.mkdir(parents=True, exist_ok=True)
    (art / "mark.svg").write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
        f'<path fill-rule="evenodd" fill="currentColor" d="{mark_path()}"/></svg>\n',
        encoding="utf-8")
    (art / f"icon-{tint}.svg").write_text(
        mark_svg(512, fg, LEGACY_SCALE, bg=bg, bg_shape=squircle(256, 256, 240, n=4.0)) + "\n",
        encoding="utf-8")
    write(art / "icon-512.png",
          png(mark_svg(512, fg, LEGACY_SCALE, bg=bg, bg_shape=shape512), 512))
    print(f"  docs/logo/mark.svg, icon-{tint}.svg")
    banner()


def banner() -> None:
    """Шапка README: знак и имя на вечернем угле — то же, что видит человек,
    когда открывает дневник ночью."""
    from PIL import ImageDraw, ImageFont

    W, H = 1280, 420
    ink, amber, cream = "#1B1107", "#FFB964", "#F4DFCB"
    card = Image.new("RGBA", (W, H), ink)
    draw = ImageDraw.Draw(card)

    fonts = ROOT / "assets/fonts"
    title = ImageFont.truetype(str(fonts / "Unbounded.ttf"), 88)
    title.set_variation_by_name("Bold")      # вариативный шрифт иначе встанет тонким
    sub = ImageFont.truetype(str(fonts / "Onest.ttf"), 29)
    sub.set_variation_by_name("Regular")

    # Репозиторий читают с обеих сторон — подпись идёт на двух языках.
    name = "Wickly"
    tag_ru = "Тёплый дневник без аккаунта"
    tag_en = "A warm journal with no account"
    tw = draw.textlength(name, font=title)
    sw = max(draw.textlength(t, font=sub) for t in (tag_ru, tag_en))
    mark_side, gap = 216, 44
    left = (W - (mark_side + gap + max(tw, sw))) / 2

    card.alpha_composite(png(mark_svg(mark_side, amber, 0.94), mark_side),
                         (int(left), (H - mark_side) // 2))
    text_x = left + mark_side + gap
    draw.text((text_x, H / 2 - 88), name, font=title, fill=amber)
    draw.text((text_x + 4, H / 2 + 32), tag_ru, font=sub, fill=cream)
    draw.text((text_x + 4, H / 2 + 72), tag_en, font=sub, fill="#A28D78")

    write(ROOT / "docs/logo/banner.png", card.convert("RGB"))


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Иконки Wickly")
    ap.add_argument("--tint", choices=sorted(TINTS), default="ember",
                    help="колеровка (по умолчанию ember — амбра на угле)")
    build(ap.parse_args().tint)
