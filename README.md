# Berean — Scripture Companion for Even Realities G2

Glanceable Scripture study on the G2 HUD. Pick a verse from the phone-side
companion panel; the glasses show the text, walk through Strong's word by
word, list cross-references, or scroll concise commentary. Designed for the
576 × 288, 4-bit monochrome-green display.

## Stack

- Vite + React + TypeScript
- `@evenrealities/even_hub_sdk` (G2 SDK)
- `@evenrealities/evenhub-simulator` (local preview on macOS)
- `@evenrealities/evenhub-cli` (packaging)

## Install

Requires Node 18+ and macOS for the simulator GUI.

```bash
npm install
```

## Run

Two terminals:

```bash
# Terminal 1 — Vite dev server (companion + plugin entry)
npm run dev
```

```bash
# Terminal 2 — G2 simulator pointed at the dev server
npm run sim
```

The simulator window shows the virtual glasses display. The Vite browser
tab (default `http://localhost:5173`) is the phone-side companion panel —
verse picker, text input, mode buttons, and a HUD mirror so you can
iterate without putting the headset on.

Production build:

```bash
npm run build      # type-check + Vite production build to dist/
npm run pack       # bundle into .ehpk for sideloading
```

## Plugin lifecycle (how the SDK is used)

The plugin keeps a single page container alive for the session.

1. `createStartUpPageContainer` is called exactly **once** on boot, with the
   `verse` screen containers (header, body, footer).
2. Switching screen modes (verse → Strong's → cross-refs → commentary)
   calls `rebuildPageContainer` with a fresh container set. The body
   container always has `isEventCapture: 1` so it receives touch events.
3. Within a screen, paging and word/cross-ref stepping uses
   `textContainerUpgrade` (partial update) on the body + footer containers
   — no flicker.

See `src/plugin/berean.ts` (`buildInitialPage`, `rebuildForMode`,
`refreshBody`).

## Screens and how to test each

Use the companion panel **Mode** buttons, or send the gesture below from
the simulator's touchpad emulator (real G2 maps the same way).

| Screen      | What it shows                                          | Tap (advance)        | Double-tap      |
|-------------|--------------------------------------------------------|----------------------|-----------------|
| Verse       | Reference + KJV text, paginated if long                | Next page            | Cycle to next mode |
| Strong's    | Tap-through tagged words: original / translit / def    | Next tagged word     | Cycle           |
| Cross-refs  | Selectable list of refs with one-line previews         | Next cross-ref       | Cycle           |
| Commentary  | Chunked Matthew Henry's Concise, scrollable            | Next chunk           | Cycle           |

Swipe up = previous (page / word / cross-ref). Swipe down = same as tap.

> **Note on gestures:** the spec asks for *long-press* to switch view
> mode, but `@evenrealities/even_hub_sdk@0.0.10`'s `OsEventTypeList`
> doesn't expose a long-press event yet (only `CLICK_EVENT`,
> `SCROLL_TOP/BOTTOM`, `DOUBLE_CLICK_EVENT`, and lifecycle events).
> We mapped mode-cycling to double-tap as the closest available discrete
> gesture; swap to long-press in `src/plugin/berean.ts → handleEvent`
> when the SDK ships one. See `DEVICE-TESTING-CHECKLIST.md`.

Companion-only shortcuts:

- **Verse picker** dropdown selects from the 8 bundled verses.
- **Type a reference** input pushes a selection by string match
  (`John 3:16`, `genesis 1:1`, etc.). This is the same code path the voice
  handler will use on hardware.
- **← Back** / **Tap (advance) →** mirrors touchpad gestures on the phone.

Mode cycling order: `verse → strongs → crossrefs → commentary → verse`.

## Adding new verses

Two files:

1. `src/data/verses.ts` — append a new `Verse` entry. Each `words[i]`
   either has a `strongs` key (referencing a number defined in
   `strongs.ts`) or is a plain particle. Provide 2–4 cross-refs and 1–3
   commentary chunks.
2. `src/data/strongs.ts` — add any new Strong's numbers you reference,
   with `original`, `translit`, `gloss`, and `definition`.

That's it. The companion picker reads from `VERSES`; the plugin reads from
both maps at render time.

## Voice input (stubbed)

The wiring exists but no microphone is opened today. See
`src/main.tsx` for the `TODO(voice)` block — uncomment to enable
`webkitSpeechRecognition` for in-WebView testing on macOS. On the real
device prefer `bridge.audioControl(true)` + server-side STT (`asr/`
template). The handler is `plugin.onVoiceInput(transcript)` and reuses the
companion's loose reference matcher.

## Layout choices

- **Three text containers** (header / body / footer) — keeps each screen
  under the SDK's 4-container per-page cap and leaves headroom for an
  image container later (e.g. Hebrew/Greek glyphs as bitmap).
- **One idea per screen, generous whitespace.** No animations beyond what
  the SDK does on rebuild — full rebuilds flicker.
- **Partial updates** (`textContainerUpgrade`) for all in-screen state
  changes; only mode switches and verse changes do a full rebuild.
- **Loose font sizing** — we don't set a font size on the container,
  letting the SDK pick a HUD-legible default. Adjust by tightening
  `lineChars`/`linesPerPage` in `src/pagination.ts` if text spills.

## What's not built yet

- No real voice input (stub only — see TODO above).
- No live API or remote verse fetching — all data is local in
  `src/data/`.
- No phone-to-glasses pairing UI — the simulator handles it.
- No Manna BC integration; Berean is standalone.

See `DEVICE-TESTING-CHECKLIST.md` for what to verify on real hardware
versus what the simulator already covers.
