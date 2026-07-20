#!/usr/bin/env python3
"""Витрина экранов для README: четыре снимка в ряд на общем фоне.

Берёт готовые снимки из `test_golden/goldens/` (их делает
`flutter test --update-goldens test_golden`) и склеивает в одну широкую
картинку — GitHub показывает её целиком, тогда как четыре отдельных файла
он растянет по колонкам таблицы и половину обрежет.

  * docs/logo/screenshots.png — 1728×812

Снимок телефона — 1170×2532 (390×844 в тройном масштабе). Полностью он в ряд
не влезет: при четырёх кадрах на каждый приходится ~390 точек ширины, и по
высоте это дало бы 844 — вдвое выше нужного. Поэтому кадр обрезается сверху:
показываем верхнюю, содержательную часть экрана, а пустой низ отбрасываем.

Запуск: python3 tool/gen_shots.py    Требует: Pillow.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
GOLDENS = ROOT / 'test_golden' / 'goldens'
OUT = ROOT / 'docs' / 'logo' / 'screenshots.png'

# Фон — уголь знака «Огонёк», тот же, что в баннере.
BG = (27, 17, 7)

# Экраны витрины. Тёмная читалка вторым кадром — чтобы обе темы были видны
# сразу, без подписи «а ещё есть тёмная».
SHOTS = [
    'journals_light',
    'reader_dark',
    'stats_light',
    'calendar_light',
]

CANVAS = (1728, 812)
PAD = 28          # поля холста
GAP = 22          # просвет между кадрами
RADIUS = 26       # скругление кадра
EDGE = (58, 42, 26)   # обводка: без неё тёмный кадр сливается с фоном


def framed(name: str, box: tuple[int, int]) -> Image.Image:
    """Снимок, обрезанный под размер ячейки и скруглённый по углам."""
    src = Image.open(GOLDENS / f'{name}.png').convert('RGB')
    w, h = box

    # Ширину подгоняем целиком, высоту берём сверху: низ телефонных снимков
    # почти всегда пустой.
    scaled = src.resize((w, round(src.height * w / src.width)), Image.LANCZOS)
    shot = scaled.crop((0, 0, w, min(h, scaled.height)))
    if shot.height < h:  # снимок оказался короче ячейки — дорисовываем фон
        padded = Image.new('RGB', (w, h), BG)
        padded.paste(shot, (0, 0))
        shot = padded

    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), RADIUS, fill=255)
    out = Image.new('RGB', (w, h), BG)
    out.paste(shot, (0, 0), mask)
    ImageDraw.Draw(out).rounded_rectangle(
        (0, 0, w - 1, h - 1), RADIUS, outline=EDGE, width=2)
    return out


def main() -> None:
    canvas = Image.new('RGB', CANVAS, BG)
    cell_w = (CANVAS[0] - PAD * 2 - GAP * (len(SHOTS) - 1)) // len(SHOTS)
    cell_h = CANVAS[1] - PAD * 2

    for i, name in enumerate(SHOTS):
        canvas.paste(framed(name, (cell_w, cell_h)), (PAD + i * (cell_w + GAP), PAD))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT, optimize=True)
    print(f'{OUT.relative_to(ROOT)} — {canvas.width}×{canvas.height}')


if __name__ == '__main__':
    main()
