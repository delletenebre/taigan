"""Build softly equalized animal voices from the credited CC0 recordings."""
from array import array
from pathlib import Path
import argparse
import math
import subprocess
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "assets/audio"
# One close, warm voice treatment for the felt characters. Keep the recorded
# pitch and articulation; round transients rather than adding cartoon effects.
FELT_VOICE = (
    "highpass=f=95,equalizer=f=350:t=q:w=0.7:g=1.5,"
    "equalizer=f=2600:t=q:w=0.8:g=-5,lowpass=f=4200,"
    "acompressor=threshold=0.16:ratio=2.5:attack=2:release=85:makeup=1,"
)


def build(source: str, output: str, filters: str, peak_db: float, tail_fade: tuple[float, float] | None = None) -> None:
    command = [
        "ffmpeg", "-v", "error", "-i", str(AUDIO / "source" / source),
        "-af", filters, "-ac", "1", "-ar", "44100", "-f", "f32le", "pipe:1",
    ]
    samples = array("f", subprocess.check_output(command))
    if sys.byteorder != "little":
        samples.byteswap()
    gain = 10 ** (peak_db / 20) / max(abs(sample) for sample in samples)
    pcm = array("h", (round(sample * gain * 32767) for sample in samples))
    if tail_fade is not None:
        start, end = (round(seconds * 44100) for seconds in tail_fade)
        pcm = pcm[:end]
        for index in range(start, len(pcm)):
            progress = (index - start) / (len(pcm) - start - 1)
            pcm[index] = round(pcm[index] * math.cos(progress * math.pi / 2) ** 2)
    rms = math.sqrt(sum(sample ** 2 for sample in pcm) / len(pcm)) / 32767
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(AUDIO / output), "wb") as result:
        result.setnchannels(1)
        result.setsampwidth(2)
        result.setframerate(44100)
        result.writeframes(pcm.tobytes())
    print(f"{output}: {len(pcm) / 44100:.3f}s, peak {peak_db:.1f} dBFS, RMS {20 * math.log10(rms):.1f} dBFS")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", choices=("sheep", "dog", "wolf"))
    only = parser.parse_args().only
    if only in (None, "sheep"):
        # Keep the user's selected sheep-plea.wav voice until its final tail.
        build(
            "lamb-and-mother-182509.ogg", "sheep-caught.wav",
            "atrim=start=1.34:end=2.25,asetpts=PTS-STARTPTS,"
            "highpass=f=180,afftdn=nf=-35,atempo=0.72,"
            "equalizer=f=650:t=q:w=0.7:g=2,"
            "equalizer=f=2200:t=q:w=0.8:g=-7,lowpass=f=2800,"
            "acompressor=threshold=0.10:ratio=3:attack=12:release=120:makeup=1,"
            "afade=t=in:d=0.16:curve=hsin,afade=t=out:st=0.63:d=0.64:curve=hsin", -11.0,
            tail_fade=(0.95, 1.18),
        )
    if only in (None, "dog"):
        build(
            "dog-bark-277058.ogg", "bark.wav",
            "atrim=end=0.25," + FELT_VOICE +
            "afade=t=in:d=0.035:curve=hsin,afade=t=out:st=0.14:d=0.11:curve=hsin", -8.0,
        )
    if only in (None, "wolf"):
        # A single recorded grumble; soften the rasp and let it recede into
        # the forest without pitch shifting or a second bark-like syllable.
        build(
            "dog-growl-625500.ogg", "wolf-caught.wav",
            "atrim=start=0.28:end=1.33,asetpts=PTS-STARTPTS," + FELT_VOICE +
            "equalizer=f=1700:t=q:w=0.8:g=-3,lowpass=f=3000,"
            "afade=t=in:d=0.07:curve=hsin,afade=t=out:st=0.66:d=0.39:curve=hsin", -8.0,
        )
