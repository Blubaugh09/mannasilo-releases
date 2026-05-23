# Device Testing Checklist

What the simulator already covers vs. what only the real G2 will tell us.

## Covered well by the simulator

- Container layout at 576 × 288 — header / body / footer geometry.
- Pagination correctness (line wrapping, page counts, off-by-one at last
  page).
- Mode cycling order and full-rebuild correctness.
- Partial-update flow (`textContainerUpgrade`) for in-screen state.
- Verse picker / loose reference matching (same path the voice handler
  will use).
- Boot path: a single `createStartUpPageContainer` then only
  `rebuildPageContainer` and `textContainerUpgrade` for the session.
- Double-tap exit path and clean unsubscribe on `SYSTEM_EXIT_EVENT`.

## Verify on the real device

### Text legibility

- [ ] Body font size — verse text at arm's length. The simulator renders
      at native pixel density on a macOS display; the real HUD is much
      smaller and dimmer. If verse text reads tight, drop
      `linesPerPage` in `src/pagination.ts` from 6 → 5.
- [ ] Header reference visibility at the corner of vision (peripheral).
- [ ] Footer indicator: is `1 / 3` legible, or does it need to be the
      page indicator only with no hint text?
- [ ] Hebrew + Greek glyph rendering — the SDK uses its own font;
      original-language characters may fall back. If glyphs are missing,
      switch the Strong's screen to use an ImageContainer with bitmap
      glyphs (note: image data goes through `updateImageRawData` after a
      placeholder container is created).
- [ ] Contrast at the edges of pages — 4-bit grayscale, the simulator's
      antialiasing is more generous than the device.

### Touchpad feel

- [ ] Single tap → advance. Confirm taps register reliably on the
      temple; the SDK normalizes `CLICK_EVENT` (=0) to `undefined`, so
      we treat both as a tap.
- [ ] Double-tap → cycle mode. **This is a substitution.** The spec
      asks for long-press, but `OsEventTypeList` in
      `@evenrealities/even_hub_sdk@0.0.10` doesn't expose a long-press
      event — only `CLICK_EVENT`, `SCROLL_TOP/BOTTOM_EVENT`,
      `DOUBLE_CLICK_EVENT`, and lifecycle events. When the SDK adds
      `LONG_PRESS_EVENT`, swap the `DOUBLE_CLICK_EVENT` branch in
      `handleEvent` (`src/plugin/berean.ts`) for it. Until then,
      verify there's no double-tap reserved for OS-level exit that
      would conflict.
- [ ] Swipe-up (`SCROLL_TOP_EVENT`) page-back and swipe-down
      (`SCROLL_BOTTOM_EVENT`) page-forward — feel-right vs. confusing
      relative to tap?
- [ ] Latency on rebuilds vs. partial updates. The plugin already prefers
      partial updates inside a mode — but if a rebuild flickers
      noticeably between modes, consider keeping all four mode layouts in
      one container set and just toggling visibility via partial
      updates (would require redesign — image/list containers don't
      hide cleanly).

### Voice input (currently stubbed)

- [ ] On macOS the simulator runs in a WebView — `webkitSpeechRecognition`
      is available but only after a user gesture. We did **not** wire
      it; the TODO block in `src/main.tsx` is the path.
- [ ] On the real device, the audio path is `bridge.audioControl(true)`
      and PCM frames arriving on `event.audioEvent.audioPcm`. We must
      stream those to an STT (server-side) — see the `asr/` template
      from `@evenrealities/evenhub-templates` for the proven pattern.
- [ ] Confirm `plugin.onVoiceInput(transcript)` picks the right verse for
      common spoken refs ("John three sixteen", "Romans eight twenty
      eight"). The current matcher only handles numeric forms — may need
      to teach it spoken numerals.

### Lifecycle

- [ ] System exit path — backing out of the plugin on the device.
      Verify `SYSTEM_EXIT_EVENT` fires and `unsubscribe()` runs; no
      leaked event listeners.
- [ ] Re-launch — `createStartUpPageContainer` must only be called
      once **per launch**. We rely on the WebView being torn down
      between launches; confirm.
- [ ] Sideload via `npm run pack` → install on the G2. Confirm
      `app.json` permissions/sdk version match the firmware.

### Performance

- [ ] Full rebuild time on mode switch. If it's perceptibly slow,
      pre-warm by computing the next mode's page text in the
      `setMode` queue before the rebuild call.
- [ ] Memory — we keep all eight verses + Strong's in memory. Fine for
      now; revisit if the verse set grows past a few hundred.
