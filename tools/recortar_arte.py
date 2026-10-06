#!/usr/bin/env python3
"""Recorta artes geradas por IA (fundo cinza-claro liso + sombra) e salva PNG transparente.

Uso:
    python3 tools/recortar_arte.py entrada.jpg saida.png [--altura 512] [--caixa x0,y0,x1,y1] [--sem-base]

- O fundo é removido por "balde de tinta" a partir das bordas: só some o que é cinza
  (pouca saturação) e ligado à borda. O contorno de nanquim funciona como barreira,
  então partes cinzas DENTRO do personagem ficam intactas.
- A sombra projetada também é removida (o jogo desenha a própria sombra).
- --caixa recorta um pedaço da imagem antes (útil para folhas com vários personagens).
- --sem-base corta a base de calçada (pedestal) abaixo dos pés, pelo limite inferior informado
  em fração da altura do recorte (ex.: --sem-base 0.86).

Requer Pillow:  pip install pillow
"""
import argparse
from collections import deque

from PIL import Image, ImageFilter


def is_background(px, sat_max=30, bright_min=70, bright_max=232):
    r, g, b = px[:3]
    sat = max(r, g, b) - min(r, g, b)
    # A sombra projetada é cinza-azulada: aceita mais saturação quando o azul domina.
    if b >= r and b >= g:
        sat_max = 60
    # Branco puro (asas, papel, metal claro) é mais claro que o fundo cinza: não apaga.
    return sat <= sat_max and bright_min <= (r + g + b) / 3 <= bright_max


def remove_background(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        if not is_background(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        if x > 0:
            q.append((x - 1, y))
        if x < w - 1:
            q.append((x + 1, y))
        if y > 0:
            q.append((x, y - 1))
        if y < h - 1:
            q.append((x, y + 1))
    # Borda suave: encolhe 1px o alfa e desfoca levemente.
    alpha = im.getchannel("A").filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    im.putalpha(alpha)
    return im


def keep_main_parts(im: Image.Image, min_frac=0.03) -> Image.Image:
    """Apaga pedacinhos soltos (letras de legenda, respingos): mantém só partes grandes."""
    a = im.getchannel("A")
    w, h = a.size
    px = a.load()
    label = [0] * (w * h)
    comps = []
    for y in range(h):
        for x in range(w):
            if px[x, y] > 40 and not label[y * w + x]:
                cid = len(comps) + 1
                q = deque([(x, y)])
                label[y * w + x] = cid
                pts = []
                while q:
                    cx, cy = q.popleft()
                    pts.append((cx, cy))
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= nx < w and 0 <= ny < h and px[nx, ny] > 40 and not label[ny * w + nx]:
                            label[ny * w + nx] = cid
                            q.append((nx, ny))
                comps.append(pts)
    if not comps:
        return im
    biggest = max(len(c) for c in comps)
    out = im.load()
    for pts in comps:
        if len(pts) < biggest * min_frac:
            for x, y in pts:
                out[x, y] = (0, 0, 0, 0)
    return im


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("entrada")
    ap.add_argument("saida")
    ap.add_argument("--altura", type=int, default=512)
    ap.add_argument("--caixa", default="")
    ap.add_argument("--sem-base", type=float, default=0.0)
    a = ap.parse_args()

    im = Image.open(a.entrada)
    if a.caixa:
        im = im.crop(tuple(int(v) for v in a.caixa.split(",")))
    im = keep_main_parts(remove_background(im))
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    if a.sem_base > 0:
        im = im.crop((0, 0, im.width, int(im.height * a.sem_base)))
        im = im.crop(im.getbbox())
    if im.height > a.altura:
        im = im.resize((round(im.width * a.altura / im.height), a.altura), Image.LANCZOS)
    im.save(a.saida, optimize=True)
    print(f"{a.saida}: {im.width}x{im.height}")


if __name__ == "__main__":
    main()
