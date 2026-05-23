/**
 * Berean plugin — Scripture study companion for Even Realities G2.
 *
 * Lifecycle:
 *   1. `start()` — wait for the bridge, build the initial verse page via
 *      `createStartUpPageContainer` (called EXACTLY once for the session).
 *   2. Any subsequent screen change ("rebuild") flips to a new container set
 *      via `rebuildPageContainer`. Page-to-page text changes within the same
 *      screen use `textContainerUpgrade` (partial update, no flicker).
 *   3. `stop()` — unsubscribe, shutdown the page container.
 */
import {
  TextContainerProperty,
  CreateStartUpPageContainer,
  RebuildPageContainer,
  TextContainerUpgrade,
  OsEventTypeList
} from '@evenrealities/even_hub_sdk'

import { VERSES, VERSE_INDEX, STRONGS } from '../data'
import type { AppState, ScreenMode, Verse } from '../types'
import { paginate, paginateChunks } from '../pagination'
import { getBridge, type BridgeHandle, type HubEvent } from './bridge'

// --- Display geometry ---------------------------------------------------
const SCREEN_W = 576
const SCREEN_H = 288

const HEADER_H = 40
const FOOTER_H = 28
const BODY_Y = HEADER_H + 4
const BODY_H = SCREEN_H - BODY_Y - FOOTER_H - 4
const FOOTER_Y = SCREEN_H - FOOTER_H

// Horizontal breathing room inside each text container.
const PAD = 12

// Container IDs we reuse across screens. The SDK keys updates by ID.
const ID_HEADER = 1
const ID_BODY = 2
const ID_FOOTER = 3

const MODE_ORDER: ScreenMode[] = ['verse', 'strongs', 'crossrefs', 'commentary']

// --- State ---------------------------------------------------------------
export type OnStateChange = (state: AppState, verse: Verse) => void

export class BereanPlugin {
  private bridge: BridgeHandle | null = null
  private unsubscribe: (() => void) | null = null
  private started = false
  private state: AppState
  private rendering: Promise<unknown> = Promise.resolve()
  private listeners = new Set<OnStateChange>()

  constructor(initialVerseId: string = VERSES[0]!.id) {
    this.state = {
      verseId: initialVerseId,
      mode: 'verse',
      page: 0,
      wordIndex: 0,
      crossRefIndex: 0
    }
  }

  // ---- public API ------------------------------------------------------
  onChange(cb: OnStateChange): () => void {
    this.listeners.add(cb)
    cb(this.state, this.currentVerse())
    return () => { this.listeners.delete(cb) }
  }

  getState(): AppState { return { ...this.state } }
  currentVerse(): Verse { return VERSE_INDEX[this.state.verseId]! }

  hasBridge(): boolean { return this.bridge !== null }

  async start(): Promise<void> {
    if (this.started) return
    this.started = true
    this.bridge = await getBridge()
    if (!this.bridge) {
      console.warn('[berean] No SDK bridge available — running companion-only.')
      this.emit()
      return
    }
    await this.buildInitialPage()
    this.unsubscribe = this.bridge.onEvenHubEvent(e => { void this.handleEvent(e) })
    this.emit()
  }

  async stop(): Promise<void> {
    this.unsubscribe?.()
    this.unsubscribe = null
    try { await this.bridge?.shutDownPageContainer(1) } catch { /* ignore */ }
  }

  /** Switch to a specific verse. Triggers a full rebuild (new container set). */
  async selectVerse(verseId: string): Promise<void> {
    if (!VERSE_INDEX[verseId] || verseId === this.state.verseId) return
    this.state = {
      verseId,
      mode: 'verse',
      page: 0,
      wordIndex: 0,
      crossRefIndex: 0
    }
    await this.rebuildForMode()
    this.emit()
  }

  /** Switch screen mode (verse → strongs → crossrefs → commentary). Rebuilds. */
  async setMode(mode: ScreenMode): Promise<void> {
    if (mode === this.state.mode) return
    this.state.mode = mode
    this.state.page = 0
    await this.rebuildForMode()
    this.emit()
  }

  /** Advance within the current mode (tap behavior). Uses partial updates. */
  async advance(): Promise<void> {
    switch (this.state.mode) {
      case 'verse':       return this.advancePage()
      case 'commentary':  return this.advancePage()
      case 'strongs':     return this.advanceWord()
      case 'crossrefs':   return this.advanceCrossRef()
    }
  }

  /** Inverse of advance — page back / previous word, etc. */
  async retreat(): Promise<void> {
    switch (this.state.mode) {
      case 'verse':
      case 'commentary':
        if (this.state.page > 0) {
          this.state.page--
          await this.refreshBody()
          this.emit()
        }
        return
      case 'strongs':
        if (this.state.wordIndex > 0) {
          this.state.wordIndex--
          await this.refreshBody()
          this.emit()
        }
        return
      case 'crossrefs':
        if (this.state.crossRefIndex > 0) {
          this.state.crossRefIndex--
          await this.refreshBody()
          this.emit()
        }
        return
    }
  }

  /** Cycle to the next mode (mapped to double-tap; see DEVICE-TESTING-CHECKLIST). */
  async cycleMode(): Promise<void> {
    const idx = MODE_ORDER.indexOf(this.state.mode)
    const next = MODE_ORDER[(idx + 1) % MODE_ORDER.length]!
    await this.setMode(next)
  }

  /**
   * Voice-input hook. Currently a stub — wire to Web Speech API on real
   * devices.
   * TODO(voice): in `src/main.tsx`, instantiate `webkitSpeechRecognition`,
   * call `.start()` on app boot, and forward `result` events to this method.
   * On real G2 hardware, use `bridge.audioControl(true)` and feed PCM frames
   * from `event.audioEvent.audioPcm` through a server-side STT.
   */
  async onVoiceInput(transcript: string): Promise<void> {
    const ref = matchVerse(transcript)
    if (ref) await this.selectVerse(ref)
  }

  // ---- rendering -------------------------------------------------------
  private emit(): void {
    const snapshot = this.getState()
    const verse = this.currentVerse()
    for (const cb of this.listeners) cb(snapshot, verse)
  }

  private queue(task: () => Promise<unknown>): Promise<unknown> {
    this.rendering = this.rendering.then(task, task)
    return this.rendering
  }

  private async buildInitialPage(): Promise<void> {
    if (!this.bridge) return
    await this.queue(async () => {
      const containers = this.composeScreen()
      await this.bridge!.createStartUpPageContainer(new CreateStartUpPageContainer({
        containerTotalNum: containers.length,
        textObject: containers
      }))
    })
  }

  private async rebuildForMode(): Promise<void> {
    if (!this.bridge) return
    await this.queue(async () => {
      const containers = this.composeScreen()
      await this.bridge!.rebuildPageContainer(new RebuildPageContainer({
        containerTotalNum: containers.length,
        textObject: containers
      }))
    })
  }

  /** Updates body + footer without rebuilding the whole page. */
  private async refreshBody(): Promise<void> {
    if (!this.bridge) return
    const { bodyText, footerText } = this.renderContent()
    await this.queue(async () => {
      await this.bridge!.textContainerUpgrade(new TextContainerUpgrade({
        containerID: ID_BODY,
        content: bodyText
      }))
      await this.bridge!.textContainerUpgrade(new TextContainerUpgrade({
        containerID: ID_FOOTER,
        content: footerText
      }))
    })
  }

  private composeScreen(): TextContainerProperty[] {
    const verse = this.currentVerse()
    const { bodyText, footerText } = this.renderContent()
    const headerText = `${verse.reference}    · ${modeLabel(this.state.mode)} ·`

    return [
      new TextContainerProperty({
        containerID: ID_HEADER,
        xPosition: 0, yPosition: 0,
        width: SCREEN_W, height: HEADER_H,
        borderWidth: 0,
        paddingLength: PAD,
        content: headerText,
        isEventCapture: 0
      }),
      new TextContainerProperty({
        containerID: ID_BODY,
        xPosition: 0, yPosition: BODY_Y,
        width: SCREEN_W, height: BODY_H,
        borderWidth: 0,
        paddingLength: PAD,
        content: bodyText,
        isEventCapture: 1
      }),
      new TextContainerProperty({
        containerID: ID_FOOTER,
        xPosition: 0, yPosition: FOOTER_Y,
        width: SCREEN_W, height: FOOTER_H,
        borderWidth: 0,
        paddingLength: PAD,
        content: footerText,
        isEventCapture: 0
      })
    ]
  }

  private renderContent(): { bodyText: string; footerText: string } {
    const v = this.currentVerse()
    switch (this.state.mode) {
      case 'verse': {
        const pages = paginate(v.text)
        const page = clamp(this.state.page, 0, pages.length - 1)
        this.state.page = page
        return {
          bodyText: pages[page] ?? '',
          footerText: `${page + 1} / ${pages.length}   tap: next   double-tap: mode`
        }
      }
      case 'commentary': {
        const pages = paginateChunks(v.commentary)
        const page = clamp(this.state.page, 0, pages.length - 1)
        this.state.page = page
        return {
          bodyText: pages[page] ?? '',
          footerText: `Commentary  ${page + 1} / ${pages.length}   tap: next`
        }
      }
      case 'strongs': {
        const tagged = v.words.filter(w => w.strongs)
        if (!tagged.length) return { bodyText: '(no tagged words)', footerText: '' }
        const idx = clamp(this.state.wordIndex, 0, tagged.length - 1)
        this.state.wordIndex = idx
        const tw = tagged[idx]!
        const s = STRONGS[tw.strongs!]
        if (!s) return { bodyText: `(missing Strong's: ${tw.strongs})`, footerText: '' }
        const body = [
          `${tw.word}   ${s.number}`,
          '',
          `${s.original}   ${s.translit}`,
          '',
          `gloss: ${s.gloss}`,
          s.definition
        ].join('\n')
        return {
          bodyText: body,
          footerText: `Strong's  ${idx + 1} / ${tagged.length}   tap: next`
        }
      }
      case 'crossrefs': {
        if (!v.crossRefs.length) return { bodyText: '(no cross-refs)', footerText: '' }
        const idx = clamp(this.state.crossRefIndex, 0, v.crossRefs.length - 1)
        this.state.crossRefIndex = idx
        // Show all refs with the selected one marked.
        const lines: string[] = []
        for (let i = 0; i < v.crossRefs.length; i++) {
          const c = v.crossRefs[i]!
          const marker = i === idx ? '>' : ' '
          lines.push(`${marker} ${c.ref}`)
          lines.push(`   ${truncate(c.preview, 38)}`)
        }
        return {
          bodyText: lines.join('\n'),
          footerText: `Cross-refs  ${idx + 1} / ${v.crossRefs.length}   tap: next`
        }
      }
    }
  }

  private async advancePage(): Promise<void> {
    const v = this.currentVerse()
    const pages = this.state.mode === 'verse'
      ? paginate(v.text)
      : paginateChunks(v.commentary)
    if (this.state.page < pages.length - 1) {
      this.state.page++
    } else {
      this.state.page = 0
    }
    await this.refreshBody()
    this.emit()
  }

  private async advanceWord(): Promise<void> {
    const tagged = this.currentVerse().words.filter(w => w.strongs)
    if (!tagged.length) return
    this.state.wordIndex = (this.state.wordIndex + 1) % tagged.length
    await this.refreshBody()
    this.emit()
  }

  private async advanceCrossRef(): Promise<void> {
    const refs = this.currentVerse().crossRefs
    if (!refs.length) return
    this.state.crossRefIndex = (this.state.crossRefIndex + 1) % refs.length
    await this.refreshBody()
    this.emit()
  }

  // ---- input -----------------------------------------------------------
  /**
   * Gesture mapping (the current SDK exposes no LONG_PRESS event — we map
   * mode-cycling to double-tap as the next-best discrete gesture; see
   * DEVICE-TESTING-CHECKLIST.md):
   *
   *   tap (CLICK_EVENT)         → advance within current mode
   *   swipe up (SCROLL_TOP)     → retreat / previous
   *   swipe down (SCROLL_BOTTOM)→ advance (alias for tap)
   *   double-tap (DOUBLE_CLICK) → cycle screen mode
   *   FOREGROUND_EXIT / SYSTEM_EXIT / ABNORMAL_EXIT → cleanup
   */
  private async handleEvent(event: HubEvent): Promise<void> {
    const sys = event.sysEvent?.eventType
    const text = event.textEvent?.eventType
    const types = [sys, text]

    if (types.includes(OsEventTypeList.SYSTEM_EXIT_EVENT)
        || types.includes(OsEventTypeList.ABNORMAL_EXIT_EVENT)
        || types.includes(OsEventTypeList.FOREGROUND_EXIT_EVENT)) {
      this.unsubscribe?.()
      this.unsubscribe = null
      return
    }

    if (types.includes(OsEventTypeList.DOUBLE_CLICK_EVENT)) {
      await this.cycleMode()
      return
    }

    if (types.includes(OsEventTypeList.SCROLL_TOP_EVENT)) {
      await this.retreat()
      return
    }
    if (types.includes(OsEventTypeList.SCROLL_BOTTOM_EVENT)) {
      await this.advance()
      return
    }

    // CLICK_EVENT (= 0) is normalized to undefined by the SDK's payload
    // parser. Treat both `0` and `undefined` (on either channel) as a tap.
    const isTap = (t: number | undefined) => t === OsEventTypeList.CLICK_EVENT || t === undefined
    if (isTap(sys) && isTap(text)) {
      await this.advance()
    }
  }
}

// --- helpers -------------------------------------------------------------
function modeLabel(m: ScreenMode): string {
  return m === 'verse' ? 'Verse'
    : m === 'strongs' ? "Strong's"
    : m === 'crossrefs' ? 'Cross-refs'
    : 'Commentary'
}

function clamp(n: number, lo: number, hi: number): number {
  if (hi < lo) return lo
  return Math.max(lo, Math.min(hi, n))
}

function truncate(s: string, n: number): string {
  return s.length <= n ? s : s.slice(0, n - 1) + '…'
}

/** Loose match of a transcript against a verse reference. */
function matchVerse(transcript: string): string | null {
  const t = transcript.toLowerCase().replace(/[^a-z0-9: ]/g, ' ').replace(/\s+/g, ' ').trim()
  if (!t) return null
  for (const v of VERSES) {
    const ref = v.reference.toLowerCase()
    if (t.includes(ref)) return v.id
    const compact = ref.replace(/\s+/g, '')
    if (t.replace(/\s+/g, '').includes(compact)) return v.id
  }
  return null
}
