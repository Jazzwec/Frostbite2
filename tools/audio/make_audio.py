"""Synthesizes Frostbite2's music loop and sound effects into assets/audio/.

Run from the project root:  python tools/audio/make_audio.py
Needs numpy and scipy. Everything is generated from code with fixed seeds, so the output is
reproducible; tweak a sound here and re-run instead of editing the .wav files. These are
placeholders until the planned ElevenLabs audio, and the game only knows them by file name.
"""

from pathlib import Path

import numpy as np
import scipy.io.wavfile as wavfile
import scipy.signal as sg

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
SFX_DIR = ROOT / "assets" / "audio" / "sfx"
MUSIC_DIR = ROOT / "assets" / "audio" / "music"
rng = np.random.default_rng(2026)


# ---------- Building blocks ----------

def secs(d):
    return np.arange(int(SR * d)) / SR


def midi_hz(n):
    return 440.0 * 2.0 ** ((n - 69) / 12.0)


def osc(freq, dur, shape="sine", phase=0.0):
    """An oscillator; `freq` may be a number or an array (a sweep)."""
    n = int(SR * dur)
    f = np.asarray(freq, dtype=float)
    if f.ndim == 0:
        f = np.full(n, float(f))
    else:
        # A sweep shorter than the sound holds its last pitch.
        f = np.pad(f, (0, max(0, n - len(f))), mode="edge")[:n]
    ph = phase + 2 * np.pi * np.cumsum(f) / SR
    if shape == "sine":
        return np.sin(ph)
    if shape == "tri":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    if shape == "saw":
        # Band-limited enough for our pitches: the first 12 harmonics.
        return sum(np.sin(k * ph) / k for k in range(1, 13)) * (2 / np.pi)
    if shape == "square":
        return sum(np.sin(k * ph) / k for k in range(1, 14, 2)) * (4 / np.pi)
    raise ValueError(shape)


def sweep(f0, f1, dur, curve=1.0):
    x = np.linspace(0, 1, int(SR * dur)) ** curve
    return f0 * (f1 / f0) ** x


def decay(dur, tau, attack=0.002):
    t = secs(dur)
    e = np.exp(-t / tau)
    a = int(SR * attack)
    if a > 0:
        e[:a] *= np.linspace(0, 1, a)
    return e


def adsr(dur, a=0.01, d=0.1, s=0.6, r=0.1):
    n = int(SR * dur)
    e = np.full(n, s)
    na, nd, nr = int(SR * a), int(SR * d), int(SR * r)
    e[:na] = np.linspace(0, 1, na)
    e[na:na + nd] = np.linspace(1, s, len(e[na:na + nd]))
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def band(x, lo, hi, order=2):
    sos = sg.butter(order, [lo, hi], "bandpass", fs=SR, output="sos")
    return sg.sosfilt(sos, x)


def low(x, cutoff, order=2):
    return sg.sosfilt(sg.butter(order, cutoff, "lowpass", fs=SR, output="sos"), x)


def high(x, cutoff, order=2):
    return sg.sosfilt(sg.butter(order, cutoff, "highpass", fs=SR, output="sos"), x)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def delay(x, seconds):
    return np.concatenate([np.zeros(int(SR * seconds)), x])


def glock(note_hz, dur, bright=1.0):
    """A glockenspiel/celesta tone: inharmonic partials, the high ones dying fastest."""
    parts = [(1.0, 1.0, 1.2), (2.76, 0.35 * bright, 0.45), (5.40, 0.18 * bright, 0.2), (8.93, 0.08 * bright, 0.1)]
    return sum(a * osc(note_hz * r, dur) * decay(dur, tau, 0.001) for r, a, tau in parts)


def ping(f, dur, tau):
    return osc(f, dur) * decay(dur, tau, 0.0005)


def pluck(note_hz, dur, damping=0.996, bright=0.5):
    """Karplus-Strong plucked string, computed a period at a time."""
    n = int(SR * dur)
    period = max(2, int(SR / note_hz))
    buf = rng.uniform(-1, 1, period)
    buf = low(buf, 1500 + 6000 * bright, 1) if period > 8 else buf
    out = np.empty(n)
    pos = 0
    while pos < n:
        take = min(period, n - pos)
        out[pos:pos + take] = buf[:take]
        nxt = np.roll(buf, -1)
        buf = damping * 0.5 * (buf + nxt)
        pos += take
    return out * decay(dur, dur * 0.6, 0.001)


def reverb_ir(seconds=2.0, tau=0.5, tone=6000, seed=0):
    r = np.random.default_rng(seed)
    t = secs(seconds)
    ir = r.uniform(-1, 1, len(t)) * np.exp(-t / tau)
    ir = low(ir, tone, 1)
    ir[0] = 0
    return ir / np.sqrt(np.sum(ir ** 2))


def reverb(x, wet=0.25, seconds=2.0, tau=0.5, seed=0):
    """Adds a reverb tail; the result is longer than `x` so the tail isn't cut off."""
    tail = wet * sg.fftconvolve(x, reverb_ir(seconds, tau, seed=seed))
    out = tail.copy()
    out[:len(x)] += x
    return trim_silence(out)


def trim_silence(x, floor=0.0015):
    loud = np.nonzero(np.abs(x) > floor * np.max(np.abs(x)))[0]
    return x[: loud[-1] + 1] if len(loud) else x


def normalize(x, peak=0.85):
    m = np.max(np.abs(x))
    return x if m == 0 else x * (peak / m)


def fade_out(x, seconds=0.01):
    n = min(len(x), int(SR * seconds))
    x = x.copy()
    x[-n:] *= np.linspace(1, 0, n)
    return x


def save(path, x):
    path.parent.mkdir(parents=True, exist_ok=True)
    data = np.clip(x, -1, 1)
    wavfile.write(path, SR, (data * 32767).astype(np.int16))


# ---------- Sound effects ----------

def sfx_chop():
    thunk = osc(sweep(150, 70, 0.18), 0.18) * decay(0.18, 0.05)
    crack = band(noise(0.08), 900, 3500) * decay(0.08, 0.015)
    click = band(noise(0.01), 3000, 8000) * decay(0.01, 0.002)
    return reverb(mix(thunk * 0.9, crack * 1.4, click * 0.6), 0.08, 0.6, 0.12)


def sfx_pick():
    ring = mix(ping(2350, 0.35, 0.09), ping(3720, 0.3, 0.06) * 0.6, ping(5150, 0.2, 0.03) * 0.4)
    tick = band(noise(0.02), 2000, 9000) * decay(0.02, 0.004)
    thud = osc(sweep(110, 60, 0.1), 0.1) * decay(0.1, 0.03)
    return reverb(mix(ring * 0.5, tick, thud * 0.6), 0.12, 0.8, 0.15)


def sfx_hammer():
    ring = mix(ping(1850, 0.22, 0.05), ping(2960, 0.18, 0.03) * 0.5)
    tick = band(noise(0.015), 1500, 7000) * decay(0.015, 0.003)
    thud = osc(sweep(180, 90, 0.08), 0.08) * decay(0.08, 0.025)
    return mix(ring * 0.45, tick, thud * 0.7)


def sfx_splash():
    body = band(noise(0.45), 500, 4000) * adsr(0.45, 0.02, 0.1, 0.4, 0.3)
    drops = np.zeros(int(SR * 0.45))
    for i in range(6):
        f0 = rng.uniform(700, 1400)
        blip = osc(sweep(f0, f0 * 1.8, 0.05), 0.05) * decay(0.05, 0.015)
        at = int(SR * rng.uniform(0.04, 0.3))
        drops[at:at + len(blip)] += blip * 0.3
    return mix(body, drops)


def sfx_swing_hit():
    whoosh = band(noise(0.18), 400, 2500) * np.hanning(int(SR * 0.18))
    thud = osc(sweep(140, 55, 0.15), 0.15) * decay(0.15, 0.04)
    slap = band(noise(0.05), 800, 4000) * decay(0.05, 0.01)
    return mix(whoosh * 0.6, delay(thud, 0.12), delay(slap * 0.8, 0.12))


def sfx_pop(pitch=1.0):
    blip = osc(sweep(520 * pitch, 1050 * pitch, 0.07, 0.5), 0.09) * decay(0.09, 0.03, 0.002)
    return blip + 0.3 * osc(sweep(1040 * pitch, 2100 * pitch, 0.07, 0.5), 0.09) * decay(0.09, 0.015)


def sfx_whoosh():
    return band(noise(0.16), 600, 3000) * np.hanning(int(SR * 0.16))


def sfx_drop():
    thump = osc(sweep(170, 80, 0.12), 0.12) * decay(0.12, 0.035)
    knock = band(noise(0.04), 600, 2500) * decay(0.04, 0.008)
    return mix(thump, knock * 0.7)


def sfx_fire():
    whoomph = low(noise(0.5), 400) * adsr(0.5, 0.03, 0.15, 0.3, 0.3) * 3
    crackles = np.zeros(int(SR * 0.5))
    for i in range(12):
        c = band(noise(0.008), 2000, 7000) * decay(0.008, 0.002)
        at = int(SR * rng.uniform(0.0, 0.45))
        crackles[at:at + len(c)] += c * rng.uniform(0.4, 1.0)
    return mix(whoomph, crackles)


def sfx_build_done():
    out = np.zeros(int(SR * 1.3))
    for i, n in enumerate([72, 76, 79, 84]):
        tone = glock(midi_hz(n), 0.9)
        at = int(SR * 0.09 * i)
        out[at:at + len(tone)] += tone * (0.8 if i < 3 else 1.0)
    sparkle = np.zeros_like(out)
    for i in range(10):
        p = ping(rng.uniform(4000, 8000), 0.25, 0.05)
        at = int(SR * (0.35 + 0.05 * i))
        sparkle[at:at + len(p)] += p * 0.15
    return reverb(out + sparkle, 0.3, 1.5, 0.35)


def sfx_thaw():
    out = np.zeros(int(SR * 1.0))
    crack = band(noise(0.06), 1500, 9000) * decay(0.06, 0.012)
    out[:len(crack)] += crack * 1.2
    for i in range(18):
        p = ping(rng.uniform(3000, 7500), 0.2, rng.uniform(0.02, 0.06))
        at = int(SR * rng.uniform(0.0, 0.35))
        out[at:at + len(p)] += p * rng.uniform(0.15, 0.4)
    chime = mix(delay(glock(midi_hz(79), 0.7), 0.25), delay(glock(midi_hz(84), 0.7), 0.33))
    return reverb(mix(out, chime * 0.5), 0.25, 1.2, 0.3)


def sfx_breath():
    return band(noise(0.6), 300, 1800) * adsr(0.6, 0.15, 0.1, 0.7, 0.3) * 0.6


def sfx_howl():
    dur = 1.6
    t = secs(dur)
    pitch = np.interp(t, [0, 0.35, 1.1, 1.6], [330, 560, 520, 380]) * (1 + 0.012 * np.sin(2 * np.pi * 5.5 * t))
    voice = osc(pitch, dur, "saw")
    voice = band(voice, 400, 1600) + 0.5 * band(voice, 2200, 3200)
    voice *= adsr(dur, 0.15, 0.2, 0.8, 0.5)
    return reverb(voice, 0.45, 2.0, 0.6)


def sfx_yelp():
    dur = 0.25
    v = osc(sweep(950, 420, dur), dur, "saw")
    return band(v, 500, 2500) * adsr(dur, 0.01, 0.05, 0.7, 0.1)


def sfx_crash():
    boom = osc(sweep(90, 35, 0.6), 0.6) * decay(0.6, 0.18)
    clatter = band(noise(0.5), 800, 6000) * decay(0.5, 0.12)
    return reverb(mix(boom * 1.2, clatter * 0.7), 0.2, 1.0, 0.3)


def sfx_warning():
    dur = 0.55
    a = osc(midi_hz(57), dur, "saw") * adsr(dur, 0.04, 0.05, 0.8, 0.1)
    b = osc(midi_hz(53), dur, "saw") * adsr(dur, 0.04, 0.05, 0.8, 0.1)
    horn = mix(a, delay(b, 0.6))
    return reverb(low(horn, 1800), 0.3, 1.2, 0.4)


def sfx_step():
    crunch = np.zeros(int(SR * 0.09))
    for i in range(7):
        g = band(noise(0.012), 2000, 7000) * decay(0.012, 0.003)
        at = int(SR * rng.uniform(0.0, 0.07))
        crunch[at:at + len(g)] += g * rng.uniform(0.4, 1.0)
    soft = low(noise(0.09), 900) * decay(0.09, 0.03)
    return mix(crunch * 0.7, soft * 1.5)


def sfx_tap():
    return mix(ping(1300, 0.06, 0.012), band(noise(0.01), 2000, 6000) * decay(0.01, 0.002) * 0.4)


def sfx_error():
    a = osc(220, 0.12, "square") * adsr(0.12, 0.005, 0.02, 0.6, 0.03)
    b = osc(165, 0.18, "square") * adsr(0.18, 0.005, 0.02, 0.6, 0.06)
    return low(mix(a, delay(b, 0.13)), 1500) * 0.6


def sfx_full():
    return low(osc(sweep(480, 240, 0.2), 0.2, "tri") * adsr(0.2, 0.005, 0.05, 0.6, 0.08), 2500)


def sfx_coin():
    return mix(glock(midi_hz(84), 0.4) * 0.7, delay(glock(midi_hz(91), 0.5), 0.07))


def sfx_blip():
    return osc(sweep(700, 900, 0.05), 0.06, "tri") * decay(0.06, 0.02) * 0.6


def wind_loop(seconds=10.0, fade=2.0):
    """Blizzard wind: noise with slow gusts, crossfaded so it loops seamlessly."""
    total = seconds + fade
    t = secs(total)
    base = noise(total)
    gust = 0.55 + 0.45 * np.sin(2 * np.pi * t / 3.3) * np.sin(2 * np.pi * t / 7.1 + 1.0)
    whistle_cut = 700 + 500 * np.sin(2 * np.pi * t / 4.7)
    body = low(base, 600, 2) * 2.5
    hiss = band(base, 1200, 4000) * 0.35
    # A breathy whistle: narrow band of noise that drifts.
    whistle = np.zeros_like(t)
    for lo in (600, 900, 1300):
        whistle += band(noise(total), lo, lo * 1.12, 2)
    w = (body + hiss + whistle * 0.4 * (whistle_cut / 1200)) * gust
    n_fade = int(SR * fade)
    head = w[:n_fade] * np.linspace(0, 1, n_fade) + w[-n_fade:] * np.linspace(1, 0, n_fade)
    return np.concatenate([head, w[n_fade:-n_fade]])


SFX = {
    "chop": sfx_chop, "pick": sfx_pick, "hammer": sfx_hammer, "splash": sfx_splash,
    "swing_hit": sfx_swing_hit, "pop": sfx_pop, "whoosh": sfx_whoosh, "drop": sfx_drop,
    "fire": sfx_fire, "build_done": sfx_build_done, "thaw": sfx_thaw, "breath": sfx_breath,
    "howl": sfx_howl, "yelp": sfx_yelp, "crash": sfx_crash, "warning": sfx_warning,
    "step": sfx_step, "tap": sfx_tap, "error": sfx_error, "full": sfx_full, "coin": sfx_coin,
    "blip": sfx_blip,
}


# ---------- Music: "Winter Town", a 32-second loop ----------

BPM = 120
BEAT = 60.0 / BPM
BARS = 16
LOOP = BARS * 4 * BEAT

# One chord per bar, as MIDI notes (pad voicing) and the bass root.
CHORDS = [
    ("C", [60, 64, 67], 36), ("G", [59, 62, 67], 43), ("Am", [57, 60, 64], 45), ("F", [57, 60, 65], 41),
    ("C", [60, 64, 67], 36), ("G", [59, 62, 67], 43), ("F", [57, 60, 65], 41), ("G", [59, 62, 67], 43),
    ("F", [57, 60, 65], 41), ("G", [59, 62, 67], 43), ("Em", [59, 64, 67], 40), ("Am", [57, 60, 64], 45),
    ("F", [57, 60, 65], 41), ("G", [59, 62, 67], 43), ("C", [60, 64, 67], 36), ("C", [60, 64, 67], 36),
]

# The bell melody: per bar, (beat, MIDI note, length in beats).
MELODY = [
    [(0, 76, 1), (1, 79, .5), (1.5, 81, .5), (2, 79, 1), (3, 76, 1)],
    [(0, 74, 1.5), (1.5, 71, .5), (2, 74, 2)],
    [(0, 72, 1), (1, 76, .5), (1.5, 79, 1.5), (3, 81, 1)],
    [(0, 77, 1.5), (1.5, 76, .5), (2, 74, 2)],
    [(0, 76, 1), (1, 79, .5), (1.5, 84, 1.5), (3, 83, 1)],
    [(0, 79, 2), (2, 74, 1), (3, 76, 1)],
    [(0, 77, 1), (1, 81, 1), (2, 79, 1), (3, 77, 1)],
    [(0, 76, 1), (1, 74, 1), (2, 79, 2)],
    [(0, 81, 1.5), (1.5, 79, .5), (2, 77, 1), (3, 76, 1)],
    [(0, 74, 1), (1, 79, 1), (2, 83, 2)],
    [(0, 79, 1.5), (1.5, 76, .5), (2, 71, 2)],
    [(0, 72, 1), (1, 76, 1), (2, 81, 2)],
    [(0, 81, 1), (1, 84, 1), (2, 81, 1), (3, 77, 1)],
    [(0, 79, 1), (1, 83, 1), (2, 86, 2)],
    [(0, 84, 1), (1, 79, .5), (1.5, 76, .5), (2, 79, 1), (3, 72, 1)],
    [(0, 72, 2.5)],
]

ARP_PATTERN = [0, 1, 2, 3, 2, 1, 2, 3]


class Track:
    """A stereo buffer longer than the loop; whatever rings past the end wraps to the start."""

    def __init__(self, tail=3.0):
        self.n = int(SR * (LOOP + tail))
        self.left = np.zeros(self.n)
        self.right = np.zeros(self.n)

    def add(self, x, at_beats, gain=1.0, pan=0.0):
        at = int(SR * at_beats * BEAT)
        x = x[: self.n - at]
        l, r = gain * np.cos((pan + 1) * np.pi / 4), gain * np.sin((pan + 1) * np.pi / 4)
        self.left[at:at + len(x)] += x * l * np.sqrt(2)
        self.right[at:at + len(x)] += x * r * np.sqrt(2)

    def stereo(self):
        return np.stack([self.left, self.right])


def pad_tone(notes, dur):
    t = secs(dur)
    out = np.zeros(len(t))
    for n in notes:
        for detune in (-0.12, 0.12):
            out += osc(midi_hz(n + detune), dur, "saw")
    out = low(out, 1400, 2)
    return out * adsr(dur, 0.35, 0.3, 0.8, 0.5) / (len(notes) * 2)


def bass_tone(note, dur):
    f = midi_hz(note)
    tone = osc(f, dur) + 0.25 * osc(2 * f, dur) + 0.1 * osc(3 * f, dur, "tri")
    return tone * adsr(dur, 0.005, 0.12, 0.5, 0.06)


def kick():
    return mix(osc(sweep(120, 42, 0.28, 0.4), 0.28) * decay(0.28, 0.09), band(noise(0.01), 1000, 4000) * decay(0.01, 0.002) * 0.3)


def clap():
    burst = np.zeros(int(SR * 0.2))
    for i, off in enumerate([0, 0.008, 0.017]):
        b = band(noise(0.12), 900, 5000) * decay(0.12, 0.03 if i == 2 else 0.006)
        burst[int(SR * off):int(SR * off) + len(b)] += b
    return burst


def shaker():
    return high(noise(0.05), 6500) * decay(0.05, 0.012)


def sleigh_bells():
    out = np.zeros(int(SR * 0.25))
    for i in range(9):
        p = ping(rng.uniform(4500, 9500), 0.12, rng.uniform(0.015, 0.04))
        at = int(SR * rng.uniform(0, 0.03))
        out[at:at + len(p)] += p * rng.uniform(0.3, 0.8)
    return out + high(noise(0.25), 7000) * decay(0.25, 0.05) * 0.4


def make_music():
    dry = Track()
    wet_send = Track()
    for bar, (name, voicing, root) in enumerate(CHORDS):
        b0 = bar * 4
        section_b = bar >= 8
        # Pad: one long chord per bar.
        p = pad_tone(voicing, 4 * BEAT + 0.4)
        dry.add(p, b0, 0.18, -0.3)
        dry.add(p, b0, 0.18, 0.3)
        wet_send.add(p, b0, 0.18)
        # Bass: a bouncy figure on the root, with an octave hop.
        for beat, note, length in [(0, root, 1), (1.5, root, .5), (2, root, 1), (3, root + 12, .5), (3.5, root, .5)]:
            dry.add(bass_tone(note, length * BEAT), b0 + beat, 0.42)
        # Plucked arpeggio in 8ths, the octave above the pad.
        tones = sorted(voicing) + [sorted(voicing)[0] + 12]
        for i, idx in enumerate(ARP_PATTERN):
            note = tones[idx] + 12
            pl = pluck(midi_hz(note), 0.6, 0.995, 0.6)
            gain = 0.16 if i % 2 == 0 else 0.11
            dry.add(pl, b0 + i * 0.5, gain, -0.45)
            wet_send.add(pl, b0 + i * 0.5, gain * 0.6)
        # Bells: the tune.
        for beat, note, length in MELODY[bar]:
            g = glock(midi_hz(note), max(1.2, length * BEAT + 0.6), 0.9)
            dry.add(g, b0 + beat, 0.30, 0.35)
            wet_send.add(g, b0 + beat, 0.45)
        # Drums.
        for beat in (0, 2):
            dry.add(kick(), b0 + beat, 0.55)
        if bar % 4 == 3:
            dry.add(kick(), b0 + 3.5, 0.35)
        for beat in (1, 3):
            c = clap()
            dry.add(c, b0 + beat, 0.16, 0.1)
            wet_send.add(c, b0 + beat, 0.12)
        for i in range(8):
            dry.add(shaker(), b0 + i * 0.5, 0.10 if i % 2 else 0.05, 0.5)
        # Sleigh bells: offbeats in the A section, every 8th in the B section.
        sleigh_beats = [i * 0.5 for i in range(8)] if section_b else [0.5, 1.5, 2.5, 3.5]
        for beat in sleigh_beats:
            dry.add(sleigh_bells(), b0 + beat, 0.07 if section_b else 0.06, -0.6)

    # A soft hall on the send.
    stereo_wet = np.stack([
        sg.fftconvolve(wet_send.left, reverb_ir(2.6, 0.75, seed=1))[: dry.n],
        sg.fftconvolve(wet_send.right, reverb_ir(2.6, 0.75, seed=2))[: dry.n],
    ])
    full = dry.stereo() + 0.35 * stereo_wet

    # Wrap everything that rings past the loop end onto the start, so the loop is seamless.
    n_loop = int(SR * LOOP)
    out = full[:, :n_loop].copy()
    tail = full[:, n_loop:]
    out[:, : tail.shape[1]] += tail
    # Gentle glue: soft-clip, then normalize.
    out = np.tanh(out * 1.2) / np.tanh(1.2)
    return normalize(out, 0.8)


def main():
    for name, fn in SFX.items():
        x = fade_out(normalize(fn(), 0.85), 0.005)
        save(SFX_DIR / f"{name}.wav", x)
    save(SFX_DIR / "wind_loop.wav", normalize(wind_loop(), 0.7))
    music = make_music()
    wavfile.write(MUSIC_DIR / "winter_town.wav", SR, (np.clip(music.T, -1, 1) * 32767).astype(np.int16))
    print(f"wrote {len(SFX) + 1} sound effects and a {LOOP:.0f} s music loop")


if __name__ == "__main__":
    main()
