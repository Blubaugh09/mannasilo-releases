# Manna Silo

A beautiful, minimalist iPhone app for personal Bible study — read the ESV, take
notes, highlight verses, tap any word for its meaning, see cross references, ask
Claude about the text, and connect your **Even Realities** smart glasses to
process their microphone audio directly in this app (no Even Realities companion
app in the loop).

Design language: white & black with quiet splashes of accent color — no sepia,
no browns.

---

## What's inside

| Tab | What it does |
| --- | --- |
| **Read** | Fetches any chapter from the ESV API. Tap a word for a definition; tap a verse number to highlight, add a note, see cross references, or ask Claude. Remembers where you left off. |
| **Ask** | A streaming chat with Claude about scripture. Can be opened pre-seeded from a specific verse. |
| **Notes** | All your study notes, anchored to verses or chapters. Create, edit, delete. |
| **Glasses** | Scan, connect, and start your Even Realities glasses' microphone — live on-device transcription you can save as a note or hand to Claude. |
| **Settings** | Paste your ESV and Claude API keys (stored in the Keychain), pick the Claude model, accent color, and reading text size. |

Notes, highlights, and your reading position are stored on-device with SwiftData.
Your API keys live in the device Keychain and are only ever sent to the ESV and
Anthropic APIs when you read or ask a question.

---

## Requirements

- **Xcode 16 or later** (the project uses file-system-synchronized groups).
- iOS **17.0+** device or simulator.
- A free **ESV API key** — https://api.esv.org/
- A **Claude API key** — https://console.anthropic.com/

---

## Getting started

1. Open `BibleStudy.xcodeproj` in Xcode.
2. Select the **MannaSilo** scheme and a simulator or your iPhone.
   - To run on a physical device, set your Apple ID team under
     *Signing & Capabilities* and change the bundle identifier if needed
     (`com.mannasilo.biblestudy`).
3. Build & run (⌘R).
4. Open **Settings** in the app and paste your ESV and Claude API keys.
5. Go to **Read** and start in John 1 — or tap the title to jump anywhere.

If you'd rather regenerate the project from the source tree, an
[XcodeGen](https://github.com/yonaskolb/XcodeGen) spec is included:
`brew install xcodegen && xcodegen generate`.

---

## Connecting Even Realities glasses

The glasses expose a standard **Nordic UART Service** over Bluetooth LE. The app:

1. Scans for peripherals advertising an `Even` name.
2. Connects and discovers the UART service.
3. Subscribes to notifications and sends the mic-enable command.
4. Receives `0xF1` audio frames, LC3-decodes them, and feeds the PCM into
   Apple's on-device Speech framework for a live transcript.

> **Important — reverse-engineered protocol.** The Even Realities mic stream is
> not an officially published API. The values in
> `BibleStudy/Glasses/GlassesProtocol.swift` are the community-documented
> protocol for the **G1**, which the **G2** is expected to follow closely. Every
> value that might differ between generations is isolated as a named constant in
> that one file. If your G2 behaves differently, capture its BLE traffic with a
> sniffer (e.g. nRF Connect) and adjust the service UUID, characteristic UUIDs,
> or command bytes there.

### Enabling live transcription (LC3 audio)

The glasses stream audio in **LC3**, the Bluetooth LE Audio codec, which iOS
does not decode natively. The app is built to **compile and run without** a
decoder — you still get connect, mic-enable, and frame reception, and the
Glasses screen shows a hint — but to turn that audio into text you add Google's
open-source LC3 library:

1. Add [`liblc3`](https://github.com/google/liblc3) to the project as a Swift
   Package or a vendored C target that produces a module named **`Liblc3`**
   exposing `lc3.h`.
2. Rebuild. The `#if canImport(Liblc3)` branch in
   `BibleStudy/Glasses/LC3Decoder.swift` activates automatically and live
   transcription lights up.
3. If your hardware uses a different LC3 frame size, adjust `frameBytes` in
   `Lc3FrameDecoder`.

---

## Project layout

```
BibleStudy/
├── App/                 App entry point + service factories
├── DesignSystem/        Theme, typography, reusable components
├── Models/              Bible canon/reference + SwiftData models
├── Services/            ESV, Claude, dictionary, cross-reference, Keychain, settings
├── Glasses/             BLE protocol, LC3 decoder, speech pipeline, BLE manager
└── Features/
    ├── Reader/          Reading surface, passage picker, definitions, cross refs
    ├── Ask/             Streaming Claude chat
    ├── Notes/           Notes list + editor
    ├── Glasses/         Glasses connect + transcript
    └── Settings/        Keys, appearance, reading prefs
```

---

## Credits

Scripture quotations are from the ESV® Bible (The Holy Bible, English Standard
Version®), © Crossway. Used by permission. All rights reserved.
