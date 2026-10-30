#!/usr/bin/env python3
"""Genera i 4 effetti sonori del gioco come file WAV (solo libreria standard).

    python3 scripts/make_sounds.py

Crea: assets/sounds/{tap,step,win,bump}.wav
Sostituiscili pure con suoni registrati: bastano WAV PCM 16 bit mono.
"""
import math
import os
import struct
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = bytearray()
        for s in samples:
            s = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(s * 32767))
        w.writeframes(bytes(frames))
    print("scritto", os.path.relpath(path))


def tone(freq, dur, vol=0.5, shape="sine"):
    n = int(RATE * dur)
    for i in range(n):
        t = i / RATE
        env = min(1.0, 40 * t) * math.exp(-3.5 * t / dur)  # attacco rapido, coda morbida
        if shape == "square":
            v = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
        else:
            v = math.sin(2 * math.pi * freq * t)
        yield vol * env * v


def sequence(*chunks):
    for c in chunks:
        yield from c


def tap():
    write_wav("tap.wav", tone(880, 0.06, 0.45))


def step():
    write_wav("step.wav", tone(523.25, 0.10, 0.35))


def win():
    notes = [523.25, 659.25, 783.99, 1046.5]  # do mi sol do
    write_wav("win.wav", sequence(*[tone(f, 0.16, 0.5) for f in notes]))


def bump():
    n = int(RATE * 0.22)
    out = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-9 * t)
        freq = 160 - 120 * t / 0.22          # scende
        v = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
        out.append(0.5 * env * v)
    write_wav("bump.wav", out)


if __name__ == "__main__":
    tap()
    step()
    win()
    bump()
