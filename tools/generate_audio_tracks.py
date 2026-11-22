#!/usr/bin/env python3
"""TSB — Generador de banda sonora de época (MVP-1337, D-067).

Sintetiza 6 pistas OGG Vorbis a partir de MELODÍAS ORIGINALES del equipo escritas
en las FORMAS de danza/canto históricas de dominio público (s. XIII-XV). No se
descarga ni se reutiliza ninguna grabación ni transcripción/edición moderna de
terceros: todo el material sonoro (melodías, contrapunto, instrumentación,
percusión, mezcla y bucle) es síntesis propia de TSB (CC0).

Formas históricas de referencia (dominio público):
  · Cantiga de Santa María (Alfonso X, s. XIII) — https://es.wikipedia.org/wiki/Cantigas_de_Santa_Mar%C3%ADa
  · Estampie / Chansonnier du Roy (s. XIII) — https://en.wikipedia.org/wiki/Estampie
  · Saltarello (danza italiana s. XIV) — https://en.wikipedia.org/wiki/Saltarello
  · Ductia (danza medieval s. XIII) — https://en.wikipedia.org/wiki/Ductia

El arreglo (instrumentación, contrapunto, percusión, mezcla y bucle) es original de TSB.
No se descarga ningún audio de terceros: solo síntesis propia.

Cadena: numpy -> WAV 44.1 kHz mono 16 bits -> ffmpeg -c:a libvorbis -> OGG Vorbis.
Bucle limpio: los eventos y la reverberación se suman de forma CIRCULAR sobre la duración
exacta del loop (las colas envuelven al inicio), más un fade de 5 ms en los extremos para
garantizar cero clicks; el motor hace crossfade de 1,5-2 s (D-067).
Normalización: pico por pista a -6 dBFS. Verificación integrada con ffprobe/ffmpeg.

Uso:
    python tools/generate_audio_tracks.py            # genera assets/audio/music/*.ogg + manifest.json
    python tools/generate_audio_tracks.py --verify   # solo verifica los OGG existentes
"""
from __future__ import annotations

import argparse
import glob
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
import wave

try:
    import numpy as np
except ImportError:  # pragma: no cover
    sys.exit("ERROR: numpy no disponible. Use el intérprete Python del equipo (DSH runtime).")

SR = 44100
TARGET_PEAK_DBFS = -6.0
FADE_MS = 5.0
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "assets", "audio", "music")

# ---------------------------------------------------------------------------
# Notas / frecuencias
# ---------------------------------------------------------------------------
_SEMI = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi_of(name: str) -> int:
    """'D4' -> 62, 'Bb4' -> 70, 'F#5' -> 78, 'rest' -> None."""
    if name is None or name == "rest":
        return None
    base, octave = name[:-1], int(name[-1])
    semi = _SEMI[base[0]]
    if len(base) > 1:
        semi += 1 if base[1] == "#" else -1
    return 12 * (octave + 1) + semi


def freq_of(name: str) -> float:
    m = midi_of(name)
    return 440.0 * (2.0 ** ((m - 69) / 12.0))


def harmonize(name: str, chord_root: str, interval: int) -> str:
    """Desplaza `name` `interval` semitonos (para voces de acompañamiento)."""
    m = midi_of(name)
    return _midi_name(m + interval)


def _midi_name(m: int) -> str:
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return f"{names[m % 12]}{m // 12 - 1}"


# ---------------------------------------------------------------------------
# Síntesis
# ---------------------------------------------------------------------------
def _env(n: int, attack: float, decay: float, sustain: float, release: float) -> np.ndarray:
    """ADSR de `n` muestras (a/d/r en segundos)."""
    a = max(1, int(attack * SR))
    d = max(1, int(decay * SR))
    r = max(1, int(release * SR))
    hold = max(0, n - a - d - r)
    env = np.concatenate([
        np.linspace(0.0, 1.0, a, endpoint=False),
        np.linspace(1.0, sustain, d, endpoint=False),
        np.full(hold, sustain),
        np.linspace(sustain, 0.0, r),
    ])
    if env.size < n:
        env = np.pad(env, (0, n - env.size))
    return env[:n]


def synth_voice(midi: int, dur: float, wave: str = "saw", adsr=(0.02, 0.08, 0.75, 0.25),
                gain: float = 1.0, vibrato: float = 0.0, seed: int = 0) -> np.ndarray:
    """Voz monofónica con envolvente; sin alias por limitación de armónicos a Nyquist."""
    n = max(8, int(dur * SR))
    f = 440.0 * (2.0 ** ((midi - 69) / 12.0))
    t = np.arange(n) / SR
    rng = np.random.default_rng(seed)
    if vibrato:
        t = t + (vibrato / (2 * math.pi * 5.0)) * np.sin(2 * math.pi * 5.0 * t)
    if wave in ("saw", "vielle", "shawm"):
        out = np.zeros(n)
        k_max = max(1, min(24, int((SR / 2) / f)))
        for k in range(1, k_max + 1):
            amp = 1.0 / (k ** (1.15 if wave == "vielle" else 1.35))
            out += amp * np.sin(2 * math.pi * f * k * t + 0.17 * k)
        if wave == "shawm":
            out += 0.25 * np.sin(2 * math.pi * 2 * f * t)
        if wave == "vielle":
            out += 0.35 * np.sin(2 * math.pi * 2 * f * t + 0.5) + 0.18 * np.sin(2 * math.pi * 3 * f * t)
        out /= max(1.0, np.max(np.abs(out)))
    elif wave in ("sine", "flute", "recorder", "brass"):
        out = np.sin(2 * math.pi * f * t)
        out += (0.32 if wave == "flute" else 0.22) * np.sin(2 * math.pi * 2 * f * t)
        if wave in ("flute", "recorder"):
            breath = rng.standard_normal(n)
            breath = np.convolve(breath, np.ones(24) / 24.0, mode="same")
            out += 0.035 * breath
        if wave == "brass":
            out += 0.28 * np.sin(2 * math.pi * 3 * f * t) + 0.14 * np.sin(2 * math.pi * 4 * f * t)
        out /= max(1.0, np.max(np.abs(out)))
    else:
        raise ValueError(f"wave desconocida: {wave}")
    return (out * _env(n, *adsr) * gain).astype(np.float32)


def pluck(midi: int, dur: float, gain: float = 1.0) -> np.ndarray:
    """Cuerda pulsada (laúd/vihuela) por suma de armónicos con decaimiento rápido."""
    n = max(8, int(dur * SR))
    f = 440.0 * (2.0 ** ((midi - 69) / 12.0))
    t = np.arange(n) / SR
    out = np.zeros(n)
    kmax = max(1, min(12, int((SR / 2) / f)))
    for k in range(1, kmax + 1):
        out += (1.0 / k ** 1.6) * np.exp(-t * (5.0 + 2.4 * k)) * np.sin(2 * math.pi * f * k * t + 0.31 * k)
    attack = np.minimum(1.0, t / 0.004)
    return (out * attack * gain).astype(np.float32)


def drone(midi: int, dur: float, gain: float = 1.0, fifth: bool = True) -> np.ndarray:
    """Bordón continuo con LFO de amplitud lento."""
    n = max(8, int(dur * SR))
    f = 440.0 * (2.0 ** ((midi - 69) / 12.0))
    t = np.arange(n) / SR
    out = np.sin(2 * math.pi * f * t) + 0.35 * np.sin(2 * math.pi * 2 * f * t)
    if fifth:
        out += 0.45 * np.sin(2 * math.pi * f * 1.4983 * t)
    lfo = 0.85 + 0.15 * np.sin(2 * math.pi * 0.12 * t)
    attack = np.minimum(1.0, t / 0.8)
    release = np.minimum(1.0, (dur - t) / 0.8)
    return (out * lfo * attack * np.clip(release, 0, 1) * gain / 2.0).astype(np.float32)


def perc(kind: str, dur: float, gain: float = 1.0, seed: int = 0) -> np.ndarray:
    """Percusión sintética: frame, tabor, nakers, bell, clap, roll."""
    n = max(8, int(dur * SR))
    t = np.arange(n) / SR
    rng = np.random.default_rng(seed)
    if kind in ("frame", "tabor"):
        f0 = 95.0 if kind == "frame" else 190.0
        f = f0 * (1.0 + 0.5 * np.exp(-t * 22.0))
        body = np.sin(2 * math.pi * f * t) * np.exp(-t * (9.0 if kind == "frame" else 14.0))
        noise = rng.standard_normal(n) * np.exp(-t * 32.0)
        noise = np.convolve(noise, np.ones(8) / 8.0, mode="same")
        out = body + 0.45 * noise
    elif kind == "nakers":
        out = (np.sin(2 * math.pi * 330.0 * t) * np.exp(-t * 18.0)
               + 0.7 * np.sin(2 * math.pi * 470.0 * t) * np.exp(-t * 22.0))
        out += 0.25 * rng.standard_normal(n) * np.exp(-t * 45.0)
    elif kind == "bell":
        out = (0.55 * np.sin(2 * math.pi * 660.0 * t) + 0.35 * np.sin(2 * math.pi * 990.0 * t)
               + 0.18 * np.sin(2 * math.pi * 1320.0 * t))
        out *= np.exp(-t * 2.2) * np.minimum(1.0, t / 0.006)
    elif kind == "clap":
        noise = rng.standard_normal(n)
        noise = np.convolve(noise, np.ones(5) / 5.0, mode="same")
        out = noise * np.exp(-t * 48.0) * 0.8
    elif kind == "roll":
        out = np.zeros(n)
        step = int(0.055 * SR)
        seg = rng.standard_normal(n)
        seg = np.convolve(seg, np.ones(6) / 6.0, mode="same")
        for i in range(0, n, step):
            ln = min(n - i, int(0.05 * SR))
            out[i:i + ln] += seg[i:i + ln] * np.linspace(0.9, 0.2, ln)
    else:
        raise ValueError(f"perc desconocida: {kind}")
    out /= max(1.0, np.max(np.abs(out)))
    return (out * gain).astype(np.float32)


# ---------------------------------------------------------------------------
# Melodías PD / propias (nota, duración en beats de negra)
# ---------------------------------------------------------------------------
CANTIGA_TSB = [  # melodía original TSB en forma de cantiga (Re dórico)
    [("A4", 1), ("G4", 0.5), ("F4", 1), ("E4", 0.5), ("F4", 1), ("G4", 1), ("D4", 1)],
    [("D4", 1), ("E4", 1), ("F4", 1), ("G4", 1), ("A4", 1), ("F4", 1)],
    [("G4", 1), ("F4", 1), ("E4", 1), ("D4", 1), ("C4", 1), ("D4", 1)],
    [("F4", 1), ("G4", 1), ("A4", 2), ("G4", 1), ("D4", 1)],
]
ESTAMPIE_TSB = [  # melodía original TSB en forma de estampie (Si bemol)
    [("F4", 2), ("Bb4", 1), ("C5", 2), ("A4", 1)],
    [("D5", 0.5), ("C5", 0.5), ("Bb4", 0.5), ("A4", 0.5), ("Bb4", 2), ("C5", 1), ("A4", 1)],
    [("Bb4", 2), ("C5", 1), ("D5", 2), ("C5", 1)],
    [("Bb4", 1), ("A4", 1), ("G4", 1), ("F4", 1), ("G4", 1), ("F4", 1)],
]
SALTARELLO_TSB = [  # melodía original TSB, forma de saltarello
    [("G4", 1), ("A4", 0.5), ("B4", 0.5), ("D5", 1), ("C5", 1), ("B4", 1), ("A4", 1)],
    [("G4", 1), ("A4", 1), ("B4", 1), ("C5", 1), ("D5", 2)],
    [("B4", 1), ("C5", 1), ("D5", 1), ("E5", 1), ("D5", 1), ("C5", 1)],
    [("A4", 1), ("G4", 1), ("A4", 1), ("B4", 1), ("G4", 2)],
]
DUCTIA_TSB = [  # melodía original TSB, forma de ductia
    [("D4", 1), ("E4", 0.5), ("F4", 0.5), ("G4", 1), ("A4", 1), ("G4", 1), ("F4", 1)],
    [("E4", 1), ("F4", 1), ("G4", 1), ("A4", 1), ("B4", 1), ("A4", 1)],
    [("G4", 1), ("A4", 1), ("B4", 1), ("C5", 1), ("B4", 1), ("A4", 1)],
    [("F4", 1), ("E4", 1), ("D4", 2), ("A4", 1), ("D4", 1)],
]
FANFARE_TSB = [  # fanfarria original TSB (motivo en Re)
    [("D4", 1), ("D4", 1), ("A4", 1), ("D5", 3)],
    [("A4", 1), ("A4", 1), ("D5", 1), ("F5", 3)],
    [("D5", 1), ("C5", 1), ("A4", 1), ("D5", 3)],
    [("F5", 1), ("E5", 1), ("D5", 1), ("A4", 1), ("D5", 2)],
]

# ---------------------------------------------------------------------------
# Configuración de las 6 pistas
# ---------------------------------------------------------------------------
TRACKS = [
    dict(
        file="menu_consort.ogg", title="Consort de menú", context="menu",
        bpm=72, target_s=84, phrases=CANTIGA_TSB, chords=["D3", "F3", "C3", "D3"],
        lead="flute", double="vielle", perc_style="soft", gain=1.0,
        composition="Original TSB — «Consort de menú» (forma de cantiga/consort, s. XIII-XV)",
        form="Cantiga de Santa María (Alfonso X, s. XIII)",
        form_reference="https://es.wikipedia.org/wiki/Cantigas_de_Santa_Mar%C3%ADa",
        source_kind="melodía original TSB; forma histórica de dominio público",
        license="Original TSB (CC0)",
        note="Melodía, arreglo y síntesis propios de TSB; no usa transcripciones, ediciones ni grabaciones de terceros.",
        instruments="flauta, viola medieval (vielle), laúd, bordón, campana suave", loop=True,
    ),
    dict(
        file="map_estampie.ogg", title="Estampie del mapa", context="map",
        bpm=80, target_s=78, phrases=ESTAMPIE_TSB, chords=["Bb2", "F2", "G2", "F2"],
        lead="recorder", double="pluck", perc_style="soft", gain=0.95,
        composition="Original TSB — «Estampie del mapa» (forma de estampie, s. XIII)",
        form="Estampie del Chansonnier du Roy (s. XIII)",
        form_reference="https://en.wikipedia.org/wiki/Estampie",
        source_kind="melodía original TSB; forma histórica de dominio público",
        license="Original TSB (CC0)",
        note="Melodía original con puncta abiertos/cerrados al estilo de las estampies; síntesis propia.",
        instruments="flauta dulce, laúd, bordón, campana", loop=True,
    ),
    dict(
        file="battle_n2_march.ogg", title="Marcha de batalla N2", context="battle_n2",
        bpm=112, target_s=66, phrases=SALTARELLO_TSB, chords=["G2", "F2", "G2", "D2"],
        lead="shawm", double="vielle", perc_style="march", gain=1.0,
        composition="Original TSB — «Saltarello de TSB» (forma de saltarello, s. XIV)",
        form="Saltarello (danza italiana, s. XIV)",
        form_reference="https://en.wikipedia.org/wiki/Saltarello",
        source_kind="melodía original TSB; forma histórica de dominio público",
        license="Original TSB (CC0)",
        note="Percusión de marcha (tambor de marco, tabal); melodía y síntesis propias.",
        instruments="chirimía, vielle, bordón, tambor de marco, tabal", loop=True,
    ),
    dict(
        file="battle_n3_combat.ogg", title="Combate cerrado N3", context="battle_n3",
        bpm=132, target_s=60, phrases=DUCTIA_TSB, chords=["D2", "D2", "F2", "D2"],
        lead="shawm", double="vielle", perc_style="combat", gain=1.05,
        composition="Original TSB — «Ductia de TSB» (forma de ductia, s. XIII)",
        form="Ductia (danza medieval, s. XIII)",
        form_reference="https://en.wikipedia.org/wiki/Ductia",
        source_kind="melodía original TSB; forma histórica de dominio público",
        license="Original TSB (CC0)",
        note="Percusión intensa (tambores, nakers, palmas); tempo rápido; melodía y síntesis propias.",
        instruments="chirimía, vielle, bordón, tambores, nakers, palmas", loop=True,
    ),
    dict(
        file="year_end.ogg", title="Fin de año", context="year_end",
        bpm=66, target_s=40, phrases=[CANTIGA_TSB[3], CANTIGA_TSB[2], CANTIGA_TSB[0], CANTIGA_TSB[3]],
        chords=["D3", "C3", "D3", "A2"], lead="recorder", double="bell", perc_style="bell", gain=0.9,
        composition="Original TSB — «Campana de fin de año» (cadencia original en forma de cantiga)",
        form="Cantiga / cadencia modal medieval (s. XIII)",
        form_reference="https://es.wikipedia.org/wiki/Cantigas_de_Santa_Mar%C3%ADa",
        source_kind="melodía original TSB; forma histórica de dominio público",
        license="Original TSB (CC0)",
        note="Pista breve de transición de año (loop=false en el motor); campana sobre la tónica; síntesis propia.",
        instruments="flauta dulce, campana, bordón", loop=False,
    ),
    dict(
        file="end_fanfare.ogg", title="Fanfarria final", context="end",
        bpm=120, target_s=36, phrases=FANFARE_TSB, chords=["D2", "A2", "D2", "A2"],
        lead="brass", double="shawm", perc_style="fanfare", gain=1.05,
        composition="Original TSB — «Fanfarria final» (forma de fanfarria/trompetería, s. XV)",
        form="Fanfarria / trompetería de corte (s. XV)",
        form_reference="https://en.wikipedia.org/wiki/Fanfare",
        source_kind="melodía original TSB; forma histórica de dominio público",
        license="Original TSB (CC0)",
        note="Cierre victoria/derrota; loop=false (stinger); melodía y síntesis propias.",
        instruments="trompeta/brass sintético, chirimía, tambores", loop=False,
    ),
]

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------
def _section_beats(phrase) -> float:
    return max(6.0, sum(d for _n, d in phrase))


def render_track(cfg: dict) -> tuple[np.ndarray, dict]:
    beat = 60.0 / cfg["bpm"]
    phrases = cfg["phrases"]
    chords = cfg["chords"]
    n_sections = max(len(phrases), len(chords))
    # Duración de un ciclo (una pasada por todos los compases)
    section_beats = [_section_beats(phrases[i % len(phrases)]) for i in range(n_sections)]
    cycle_beats = sum(section_beats)
    cycle_s = cycle_beats * beat
    cycles = max(1, int(round(cfg["target_s"] / cycle_s)))
    loop_s = cycles * cycle_s
    n = int(round(loop_s * SR))
    buf = np.zeros(n, dtype=np.float32)
    rng = np.random.default_rng(int.from_bytes(hashlib.sha256(cfg["file"].encode()).digest()[:4], "big"))

    def add(start_s: float, wave_data: np.ndarray, gain: float = 1.0) -> None:
        i0 = int(round(start_s * SR)) % n
        idx = (i0 + np.arange(wave_data.size)) % n
        np.add.at(buf, idx, (wave_data * gain).astype(np.float32))

    t = 0.0  # posición en segundos dentro del loop
    for sec in range(n_sections * cycles):
        phrase = phrases[sec % len(phrases)]
        chord_root = chords[sec % len(chords)]
        root_midi = midi_of(chord_root)
        target_len = _section_beats(phrase) * beat
        # --- bordón del compás ---
        add(t, drone(root_midi, target_len, gain=0.5, fifth=True))
        # --- acompañamiento pulsado ---
        pos = 0.0
        for k, (pname, pdur) in enumerate(phrase):
            if k % 2 == 0:
                add(t + pos, pluck(root_midi + 12, min(1.4, pdur * beat * 2.0), gain=0.22))
                add(t + pos + pdur * beat * 0.5,
                    pluck(root_midi + 19, min(1.0, pdur * beat), gain=0.13))
            pos += pdur * beat
        # --- melodía ---
        pos = 0.0
        cycle_idx = sec // n_sections
        octave = 0 if cycle_idx % 2 == 0 else 12
        for (pname, pdur) in phrase:
            if pname != "rest":
                dur = pdur * beat
                midi = midi_of(pname) + octave
                add(t + pos, synth_voice(midi, dur * 1.05, wave=cfg["lead"], gain=0.55,
                                         adsr=(0.02, 0.06, 0.8, min(0.25, dur * 0.5)),
                                         vibrato=0.0025, seed=sec * 7 + int(pos * 100)))
                # doblaje a la octava/tercera con el segundo instrumento
                if cfg["double"] == "bell":
                    add(t + pos, perc("bell", min(2.5, dur * 3.0), gain=0.18, seed=sec))
                elif cfg["double"] == "pluck":
                    add(t + pos, pluck(midi - 12, min(1.6, dur * 2.0), gain=0.32))
                else:
                    add(t + pos, synth_voice(midi - 12, dur * 1.1, wave=cfg["double"], gain=0.22,
                                             adsr=(0.05, 0.1, 0.7, min(0.3, dur * 0.5)),
                                             vibrato=0.002, seed=sec * 11))
            pos += pdur * beat
        # --- percusión ---
        style = cfg["perc_style"]
        beats = max(1, int(round(target_len / beat)))
        if style == "soft":
            add(t, perc("frame", 0.35, gain=0.22, seed=sec * 3))
            add(t + target_len * 0.5, perc("frame", 0.3, gain=0.14, seed=sec * 3 + 1))
        elif style == "bell":
            add(t, perc("bell", 3.0, gain=0.30, seed=sec * 5))
        elif style == "march":
            for b in range(beats):
                add(t + b * beat, perc("tabor", 0.20, gain=0.42 if b % 2 == 0 else 0.28, seed=sec * 13 + b))
            add(t, perc("frame", 0.4, gain=0.35, seed=sec))
        elif style == "combat":
            for b in range(beats):
                add(t + b * beat, perc("tabor", 0.16, gain=0.5, seed=sec * 17 + b))
                add(t + b * beat + beat * 0.5, perc("nakers", 0.14, gain=0.3, seed=sec * 17 + b + 1))
            add(t, perc("frame", 0.45, gain=0.45, seed=sec * 19))
            if sec % 4 == 3:
                add(t + target_len - beat, perc("roll", beat, gain=0.4, seed=sec * 23))
        elif style == "fanfare":
            add(t, perc("roll", min(1.2, target_len * 0.5), gain=0.5, seed=sec * 29))
            for b in range(0, beats, 2):
                add(t + b * beat, perc("frame", 0.3, gain=0.35, seed=sec * 31 + b))
        t += target_len

    # --- reverberación circular (envuelve el loop -> sin discontinuidad) ---
    ir_len = int(1.1 * SR)
    ir_t = np.arange(ir_len) / SR
    ir = np.random.default_rng(12345).standard_normal(ir_len) * np.exp(-ir_t / 0.55)
    ir = np.convolve(ir, np.ones(20) / 20.0, mode="same")
    ir[: int(0.008 * SR)] += 0.35  # reflexión temprana
    ir = np.pad(ir, (0, max(0, n - ir_len)))[:n]
    wet = np.fft.irfft(np.fft.rfft(buf) * np.fft.rfft(ir), n=n)
    mix = buf + (wet / max(1e-9, np.max(np.abs(wet)))) * 0.16 * max(1e-9, np.max(np.abs(buf)))
    mix = mix.astype(np.float32)

    # --- fade corto en los extremos (cero click; el motor hace crossfade) ---
    fade = int(FADE_MS / 1000.0 * SR)
    ramp = np.linspace(0.0, 1.0, fade, dtype=np.float32)
    mix[:fade] *= ramp
    mix[-fade:] *= ramp[::-1]

    # --- normalización a -6 dBFS ---
    peak = float(np.max(np.abs(mix)))
    gain = (10.0 ** (TARGET_PEAK_DBFS / 20.0)) / max(peak, 1e-9)
    mix = (mix * gain).astype(np.float32)
    info = {
        "duration_s": round(n / SR, 3), "loop": cfg["loop"], "bpm": cfg["bpm"],
        "cycles": cycles, "peak_dbfs": round(20 * math.log10(max(float(np.max(np.abs(mix))), 1e-9)), 2),
        "rms_dbfs": round(20 * math.log10(max(float(np.sqrt(np.mean(mix ** 2))), 1e-9)), 2),
    }
    return mix, info


def write_wav(path: str, samples: np.ndarray) -> None:
    pcm = np.clip(samples * 32767.0, -32768, 32767).astype("<i2")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())


def find_tool(name: str) -> str:
    pattern = rf"C:\Users\horac\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg*\**\bin\{name}.exe"
    matches = sorted(glob.glob(pattern, recursive=True))
    if matches:
        return matches[-1]
    which = shutil.which(name)
    if which:
        return which
    raise FileNotFoundError(f"No se encontró {name}.exe (Gyan.FFmpeg) ni en PATH")


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def probe_ogg(path: str, ffmpeg: str, ffprobe: str) -> dict:
    with open(path, "rb") as fh:
        head = fh.read(256)
    vorbis_header = head[:4] == b"OggS" and b"vorbis" in head
    out = subprocess.run(
        [ffprobe, "-v", "error", "-select_streams", "a:0", "-show_entries",
         "stream=codec_name,sample_rate,channels,duration", "-of", "json", path],
        capture_output=True, text=True, check=False)
    meta = json.loads(out.stdout or "{}").get("streams", [{}])[0]
    # decodifica a WAV para medir pico/clipping y discontinuidad del bucle
    with tempfile.TemporaryDirectory(prefix="tsb_audio_verify_") as td:
        dec = os.path.join(td, "dec.wav")
        subprocess.run([ffmpeg, "-y", "-v", "error", "-i", path, "-f", "wav", dec], check=True, capture_output=True)
        with wave.open(dec, "rb") as f:
            frames = f.readframes(f.getnframes())
            rate = f.getframerate()
        pcm = np.frombuffer(frames, dtype="<i2").astype(np.float32)
    peak = float(np.max(np.abs(pcm))) / 32768.0
    clip_count = int(np.sum(np.abs(pcm) >= 32767))
    jump = float(abs(pcm[0] - pcm[-1])) / 32768.0
    deriv = float(abs((pcm[0] - pcm[-1]) - (pcm[-1] - pcm[-2]))) / 32768.0
    return {
        "vorbis_header": bool(vorbis_header),
        "codec": meta.get("codec_name", ""), "sample_rate": int(rate),
        "channels": int(meta.get("channels", 1)),
        "duration_s": round(decoded_duration(frames, rate), 3),
        "peak_dbfs": round(20 * math.log10(max(peak, 1e-9)), 2),
        "rms_dbfs": round(20 * math.log10(max(float(np.sqrt(np.mean((pcm / 32768.0) ** 2))), 1e-9)), 2),
        "clipped_samples": clip_count,
        "loop_jump": round(jump, 5), "loop_deriv": round(deriv, 5),
    }


def decoded_duration(frames: bytes, rate: int) -> float:
    return len(frames) / (rate * 2.0)


def build(verify_only: bool = False, only: set[str] | None = None) -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    ffmpeg = find_tool("ffmpeg")
    ffprobe = find_tool("ffprobe")
    manifest = {
        "schema_version": 2,
        "generated_by": "tools/generate_audio_tracks.py (AG-5, D-067)",
        "sample_rate": SR, "format": "OGG Vorbis (libvorbis q5), mono",
        "target_peak_dbfs": TARGET_PEAK_DBFS,
        "melodies_disclaimer": ("Todas las melodías, arreglos e instrumentación son originales de TSB (CC0), "
                                "escritos en formas históricas de dominio público (cantiga, estampie, saltarello, "
                                "ductia, fanfarria). No se usa ninguna transcripción, edición ni grabación de "
                                "terceros; no se descarga audio."),
        "tracks": [],
    }
    failures = []
    with tempfile.TemporaryDirectory(prefix="tsb_audio_build_") as td:
        for cfg in TRACKS:
            out_path = os.path.join(OUT_DIR, cfg["file"])
            render = (not verify_only) and (only is None or cfg["file"] in only)
            if render:
                mix, info = render_track(cfg)
                wav_path = os.path.join(td, cfg["file"].replace(".ogg", ".wav"))
                write_wav(wav_path, mix)
                subprocess.run([
                    ffmpeg, "-y", "-v", "error", "-i", wav_path,
                    "-c:a", "libvorbis", "-qscale:a", "5", "-ar", str(SR), "-ac", "1",
                    "-metadata", f"title={cfg['title']}",
                    "-metadata", "artist=The Sovereign's Blood (AG-5)",
                    "-metadata", f"comment={cfg['license']}",
                    out_path,
                ], check=True, capture_output=True)
            probe = probe_ogg(out_path, ffmpeg, ffprobe)
            track = {
                "track": cfg["file"], "context": cfg["context"], "title": cfg["title"],
                "composition": cfg["composition"], "form": cfg["form"],
                "form_reference": cfg["form_reference"],
                "source_url": None, "source_kind": cfg["source_kind"], "license": cfg["license"],
                "note": cfg["note"],
                "arrangement": "melodía, arreglo, instrumentación, percusión y síntesis originales de TSB (AG-5)",
                "instruments": cfg["instruments"],
                "duration_s": probe["duration_s"], "loop": cfg["loop"], "bpm": cfg["bpm"],
                "sample_rate": probe["sample_rate"], "channels": probe["channels"],
                "codec": probe["codec"], "peak_dbfs": probe["peak_dbfs"], "rms_dbfs": probe["rms_dbfs"],
                "clipped_samples": probe["clipped_samples"],
                "loop_jump": probe["loop_jump"], "loop_deriv": probe["loop_deriv"],
                "sha256": sha256(out_path), "bytes": os.path.getsize(out_path),
            }
            manifest["tracks"].append(track)
            ok = (probe["vorbis_header"] and probe["codec"] == "vorbis"
                  and probe["sample_rate"] == SR and probe["duration_s"] > 30.0
                  and probe["clipped_samples"] == 0 and probe["peak_dbfs"] < -0.5)
            print(f"[{'OK' if ok else 'FAIL'}] {cfg['file']:22s} {probe['duration_s']:7.2f}s "
                  f"{probe['sample_rate']} Hz {probe['codec']:7s} peak={probe['peak_dbfs']:6.2f} dBFS "
                  f"clip={probe['clipped_samples']} loop_jump={probe['loop_jump']:.5f}"
                  f"{' (regenerada)' if render else ' (mantenida)'}")
            if not ok:
                failures.append(cfg["file"])
    manifest_path = os.path.join(OUT_DIR, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)
    print(f"\nManifiesto: {manifest_path}")
    if failures:
        print(f"FALLOS: {failures}")
        return 1
    print("6/6 pistas OK")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Generador de banda sonora original TSB en formas PD (D-067)")
    ap.add_argument("--verify", action="store_true", help="solo verifica los OGG existentes")
    ap.add_argument("--only", default="", help="lista separada por comas de ficheros a regenerar")
    args = ap.parse_args()
    only = {x.strip() for x in args.only.split(",") if x.strip()} or None
    return build(verify_only=args.verify, only=only)


if __name__ == "__main__":
    raise SystemExit(main())
