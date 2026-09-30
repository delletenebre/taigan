"""Original quiet pentatonic plucked loop for Taigan; no external samples."""
import math, random, wave
from array import array
from pathlib import Path
RATE = 22050
DURATION = 32
random.seed(7)
signal = [0.0] * (RATE * DURATION)
# Four slow phrases, open fifths and a sparse pentatonic melody.
melody = [62, 69, 67, 64, 62, 57, 64, 67, 69, 74, 71, 69, 67, 64, 62, 57]
def pluck(start, midi, gain, length=3.5):
    frequency = 440 * 2 ** ((midi - 69) / 12)
    offset = int(start * RATE)
    for i in range(int(length * RATE)):
        t = i / RATE
        attack = min(1, t / .012)
        tone = math.sin(2 * math.pi * frequency * t)
        tone += .22 * math.sin(4 * math.pi * frequency * t) * math.exp(-t * 3)
        tone += .06 * math.sin(6 * math.pi * frequency * t) * math.exp(-t * 5)
        signal[(offset + i) % len(signal)] += gain * attack * math.exp(-t * 1.7) * tone
for j, midi in enumerate(melody):
    pluck(j * 2, midi, .16)
    if j % 4 == 0:
        pluck(j * 2, 38 if j < 8 else 43, .11, 6)
        pluck(j * 2 + .15, 45 if j < 8 else 50, .07, 5)
# Circular quiet echoes keep the loop continuous.
original = signal[:]
for delay, gain in [(int(.26 * RATE), .18), (int(.53 * RATE), .08)]:
    for i, sample in enumerate(original): signal[(i + delay) % len(signal)] += sample * gain
pcm = array('h', (round(max(-1, min(1, v)) * 32767) for v in signal))
path = Path('assets/audio/jailoo-music.wav')
with wave.open(str(path), 'wb') as out:
    out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
    out.writeframes(pcm.tobytes())
print(path)
