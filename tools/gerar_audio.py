#!/usr/bin/env python3
"""Gera os efeitos sonoros e a música provisórios do jogo (síntese simples, sem samples de terceiros).

Uso:  python3 tools/gerar_audio.py   →  escreve assets/audio/*.wav

Tudo é sintetizado: zabumba, triângulo e uma "sanfona" de onda quadrada para o forró do menu/arena,
e efeitos curtos para chute, ricochete, acerto, explosão etc. Substituir por áudio definitivo depois
é só sobrescrever o .wav com o mesmo nome.
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(1554)


def save(name, samples, gain=0.9):
    peak = max(1e-6, max(abs(s) for s in samples))
    k = gain / peak
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * k)) * 32000)) for s in samples))


def env(i, n, attack=0.005, release=1.0):
    t = i / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * (1.0 - i / n) ** release


def tone(freq, dur, kind="sine", vol=1.0, release=1.5, slide=0.0):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        f = freq + slide * (i / n)
        ph += f / SR
        x = ph % 1.0
        if kind == "sine":
            s = math.sin(2 * math.pi * x)
        elif kind == "square":
            s = 1.0 if x < 0.5 else -1.0
        elif kind == "saw":
            s = 2 * x - 1
        else:  # triangle
            s = 4 * abs(x - 0.5) - 1
        out.append(s * vol * env(i, n, release=release))
    return out


def noise(dur, vol=1.0, release=2.0, lowpass=0.0):
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        s = random.uniform(-1, 1)
        if lowpass:
            prev = prev + lowpass * (s - prev)
            s = prev
        out.append(s * vol * env(i, n, release=release))
    return out


def mix(*tracks, offsets=None):
    offsets = offsets or [0] * len(tracks)
    n = max(len(t) + o for t, o in zip(tracks, offsets))
    out = [0.0] * n
    for t, o in zip(tracks, offsets):
        for i, s in enumerate(t):
            out[i + o] += s
    return out


def kick_drum(dur=0.25, f0=110):
    return mix(tone(f0, dur, "sine", 1.0, 2.5, slide=-f0 * 0.6), noise(0.02, 0.4, 3))


# ------------------------------------------------------------------ efeitos

def sfx():
    save("chute", mix(kick_drum(0.14, 150), noise(0.05, 0.5, 4, lowpass=0.5)), 0.7)
    save("ricochete", tone(1300, 0.05, "triangle", 1.0, 3, slide=-300), 0.45)
    save("acerto", mix(tone(520, 0.07, "square", 0.5, 4, slide=-200), noise(0.04, 0.6, 5, lowpass=0.4)), 0.55)
    save("explosao", mix(noise(0.55, 1.0, 1.6, lowpass=0.12), tone(70, 0.4, "sine", 0.9, 2, slide=-40)), 0.9)
    save("abate", mix(tone(880, 0.06, "square", 0.4, 3), tone(1320, 0.08, "triangle", 0.5, 3)), 0.45)
    save("pegar", mix(tone(660, 0.12, "triangle", 0.8, 2), tone(990, 0.15, "triangle", 0.6, 2), offsets=[0, 900]), 0.6)
    save("gema", tone(1760, 0.06, "sine", 1.0, 2, slide=600), 0.35)
    save("dano", mix(tone(90, 0.3, "square", 0.6, 2, slide=-40), noise(0.2, 0.6, 2, lowpass=0.2)), 0.85)
    notes = [523, 659, 784, 1047]
    save("nivel", mix(*[tone(f, 0.18, "square", 0.45, 1.2) for f in notes], offsets=[int(SR * 0.07 * i) for i in range(4)]), 0.6)
    save("receita", mix(*[tone(f, 0.25, "triangle", 0.6, 1.0) for f in (392, 494, 587, 784, 988)],
                        offsets=[int(SR * 0.06 * i) for i in range(5)]), 0.7)
    save("chefe", mix(tone(110, 1.4, "saw", 0.6, 0.6, slide=-20), tone(165, 1.4, "saw", 0.4, 0.6, slide=-30),
                      noise(1.4, 0.2, 1, lowpass=0.05)), 0.8)
    save("vitoria", mix(*[tone(f, 0.3, "square", 0.45, 1.0) for f in (523, 659, 784, 1047, 784, 1047)],
                        offsets=[int(SR * 0.13 * i) for i in range(6)]), 0.65)
    save("derrota", mix(*[tone(f, 0.4, "triangle", 0.6, 1.0) for f in (392, 349, 311, 262)],
                        offsets=[int(SR * 0.22 * i) for i in range(4)]), 0.65)
    save("botao", tone(880, 0.04, "triangle", 1.0, 3), 0.35)
    save("aviso", mix(tone(740, 0.08, "square", 0.5, 2), tone(740, 0.08, "square", 0.5, 2), offsets=[0, int(SR * 0.12)]), 0.45)
    save("buzina", mix(tone(392, 0.35, "square", 0.5, 0.5), tone(494, 0.35, "square", 0.4, 0.5)), 0.4)


# ------------------------------------------------------------------ música (forró/baião provisório)

def music():
    bpm = 116
    beat = 60.0 / bpm
    bars = 8
    total = int(SR * beat * 4 * bars)
    out = [0.0] * total

    def put(track, t):
        o = int(t * SR)
        for i, s in enumerate(track):
            if o + i < total:
                out[o + i] += s

    zab_low = kick_drum(0.3, 70)
    zab_hi = mix(noise(0.05, 0.4, 4, lowpass=0.3), tone(220, 0.06, "sine", 0.4, 3))
    tri = tone(5200, 0.06, "triangle", 0.18, 4)
    tri_open = tone(5200, 0.25, "triangle", 0.12, 1.5)
    # Baião: zabumba no 1 e no "e" do 2; bacalhau (resposta aguda) no contratempo.
    for bar in range(bars):
        t0 = bar * 4 * beat
        for b in (0.0, 1.5, 2.0, 3.5):
            put([s * 0.9 for s in zab_low], t0 + b * beat)
        for b in (1.0, 3.0):
            put(zab_hi, t0 + b * beat)
        for k in range(8):
            put(tri_open if k % 2 == 1 else tri, t0 + k * beat * 0.5)
    # Baixo e "sanfona" (onda quadrada com vibrato leve) em modo mixolídio.
    roots = [196, 196, 175, 175, 196, 196, 147, 175]  # G G F F G G D F
    melody = [
        [784, 0, 698, 784, 880, 784, 698, 587],
        [659, 698, 784, 0, 784, 698, 659, 587],
        [523, 0, 587, 659, 698, 659, 587, 523],
        [587, 659, 523, 0, 587, 0, 0, 0],
    ]
    for bar in range(bars):
        t0 = bar * 4 * beat
        r = roots[bar]
        for b, f in ((0, r), (1.5, r * 1.5), (2, r), (3, r * 1.25)):
            put(tone(f / 2, beat * 0.9, "triangle", 0.35, 1.2), t0 + b * beat)
        line = melody[bar % 4]
        for k, f in enumerate(line):
            if f:
                n = int(SR * beat * 0.48)
                acc = []
                for i in range(n):
                    vib = 1 + 0.006 * math.sin(2 * math.pi * 5.5 * i / SR)
                    x = (f * vib * i / SR) % 1.0
                    s = (1.0 if x < 0.42 else -1.0) * 0.6 + math.sin(2 * math.pi * f * 2 * i / SR) * 0.15
                    acc.append(s * 0.16 * env(i, n, attack=0.02, release=0.6))
                put(acc, t0 + k * beat * 0.5)
    save("musica_forro", out, 0.75)


if __name__ == "__main__":
    sfx()
    music()
    print("áudio gerado em", os.path.abspath(OUT))
