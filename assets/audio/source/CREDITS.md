# Animal voice recordings

All source recordings are released under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).
These are the publicly available Ogg previews, retained here for reproducible processing.

- `lamb-bleat-787563.ogg`: **Sheep - Lamb Bleat**, TheKingOfGeeks360.
  [Source and licence](https://freesound.org/people/TheKingOfGeeks360/sounds/787563/).
  Former source for `sheep-caught.wav`, retained for comparison.
- `lamb-and-mother-182509.ogg`: **Lamb and Mother**, swiftoid.
  [Source and licence](https://freesound.org/people/swiftoid/sounds/182509/).
  Used for `sheep-caught.wav`: only the first baby-lamb call at 1.34–2.25 s,
  with noise reduction, pitch-preserving time stretching,
  softened upper harmonics, compression and endpoint fades. The selected
  voice is retained through 0.95 s; only its final tail is softened and
  shortened to 1.18 s, also saved to `docs/audio/sheep-plea.wav`.
  The mother's call is omitted.
- `dog-bark-277058.ogg`: **Single Dog Bark**, kwahmah_02.
  [Source and licence](https://freesound.org/people/kwahmah_02/sounds/277058/).
  Used for `bark.wav`.
- `dog-growl-625500.ogg`: **Animal Dog Growl 01.wav**, abhisheky948.
  [Source and licence](https://freesound.org/people/abhisheky948/sounds/625500/).
  Used for the wolf's departure voice, `wolf-caught.wav`. A short recorded
  grumble with softened rasp and a gentle fade, retaining the source pitch.

Downloaded 2026-09-30. Processing: mono conversion, gentle equalization,
compression, endpoint fades and peak normalization. Original pitch retained.
Rebuild with `python3 tools/build_animal_audio.py` (requires FFmpeg).
Rebuild only the wolf with `python3 tools/build_animal_audio.py --only wolf`.
Rebuild only the sheep with `python3 tools/build_animal_audio.py --only sheep`.
