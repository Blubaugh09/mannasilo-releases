import { useEffect, useMemo, useState } from 'react'
import type { BereanPlugin } from '../plugin/berean'
import type { AppState, ScreenMode, Verse } from '../types'
import { VERSES, STRONGS } from '../data'
import { paginate, paginateChunks } from '../pagination'

interface Props {
  plugin: BereanPlugin
  bridgeAvailable: boolean
}

const MODES: ScreenMode[] = ['verse', 'strongs', 'crossrefs', 'commentary']
const MODE_LABEL: Record<ScreenMode, string> = {
  verse: 'Verse',
  strongs: "Strong's",
  crossrefs: 'Cross-refs',
  commentary: 'Commentary'
}

export function ControlPanel({ plugin, bridgeAvailable }: Props) {
  const [state, setState] = useState<AppState>(() => plugin.getState())
  const [verse, setVerse] = useState<Verse>(() => plugin.currentVerse())
  const [query, setQuery] = useState('')

  useEffect(() => plugin.onChange((s, v) => {
    setState(s)
    setVerse(v)
  }), [plugin])

  const hud = useMemo(() => renderHud(state, verse), [state, verse])

  function submitQuery() {
    const q = query.trim()
    if (!q) return
    // Reuses the same loose matcher as voice input.
    plugin.onVoiceInput(q)
    setQuery('')
  }

  return (
    <div className="companion">
      <header>
        <h1>Berean — Scripture Companion</h1>
        <div className="subtitle">
          {bridgeAvailable
            ? 'Connected to G2 bridge. Phone-side controls below mirror the glasses display.'
            : 'No G2 bridge detected — running companion preview only. Launch the simulator to push to glasses.'}
        </div>
      </header>

      <section className="card">
        <h2>HUD preview (576 × 288)</h2>
        <div className="hud">
          <div className="hud-inner">
            <div className="hud-header">
              <span>{hud.headerLeft}</span>
              <span>{hud.headerRight}</span>
            </div>
            <div className="hud-body">{hud.body}</div>
            <div className="hud-footer">
              <span>{hud.footerLeft}</span>
              <span>{hud.footerRight}</span>
            </div>
          </div>
        </div>
        <div className="hint">Monochrome green on black, 4-bit grayscale on device.</div>
      </section>

      <section className="card">
        <h2>Verse picker</h2>
        <select
          value={state.verseId}
          onChange={e => plugin.selectVerse(e.target.value)}
        >
          {VERSES.map(v => (
            <option key={v.id} value={v.id}>
              {v.reference} ({v.testament})
            </option>
          ))}
        </select>
        <div className="row" style={{ marginTop: 10 }}>
          <input
            type="text"
            placeholder='Type a reference, e.g. "John 3:16"'
            value={query}
            onChange={e => setQuery(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter') submitQuery() }}
          />
          <button className="primary" onClick={submitQuery}>Push</button>
        </div>
        <div className="hint">Same code path the voice handler will use on hardware.</div>
      </section>

      <section className="card">
        <h2>View mode</h2>
        <div className="modes">
          {MODES.map(m => (
            <button
              key={m}
              className={state.mode === m ? 'ghost active' : 'ghost'}
              onClick={() => plugin.setMode(m)}
            >
              {MODE_LABEL[m]}
            </button>
          ))}
        </div>
        <div className="controls" style={{ marginTop: 10 }}>
          <button className="ghost" onClick={() => plugin.retreat()}>← Back</button>
          <button className="primary" onClick={() => plugin.advance()}>Tap (advance) →</button>
        </div>
        <div className="controls full" style={{ marginTop: 8 }}>
          <button className="ghost" onClick={() => plugin.cycleMode()}>Long-press (cycle view)</button>
        </div>
      </section>

      <section className="card">
        <h2>Status</h2>
        <div className="status">
          mode: {state.mode} · page: {state.page + 1} · wordIndex: {state.wordIndex} · crossRefIndex: {state.crossRefIndex}
        </div>
      </section>
    </div>
  )
}

// --- mirror rendering ----------------------------------------------------
function renderHud(state: AppState, verse: Verse) {
  const headerLeft = verse.reference
  const headerRight = MODE_LABEL[state.mode]

  switch (state.mode) {
    case 'verse': {
      const pages = paginate(verse.text)
      const page = Math.min(state.page, pages.length - 1)
      return {
        headerLeft, headerRight,
        body: pages[page] ?? '',
        footerLeft: `${page + 1} / ${pages.length}`,
        footerRight: 'tap: next · long-press: mode'
      }
    }
    case 'commentary': {
      const pages = paginateChunks(verse.commentary)
      const page = Math.min(state.page, pages.length - 1)
      return {
        headerLeft, headerRight,
        body: pages[page] ?? '',
        footerLeft: `${page + 1} / ${pages.length}`,
        footerRight: 'tap: next'
      }
    }
    case 'strongs': {
      const tagged = verse.words.filter(w => w.strongs)
      if (!tagged.length) return { headerLeft, headerRight, body: '(no tagged words)', footerLeft: '', footerRight: '' }
      const idx = Math.min(state.wordIndex, tagged.length - 1)
      const tw = tagged[idx]!
      const s = STRONGS[tw.strongs!]
      const body = s
        ? `${tw.word}   ${s.number}\n\n${s.original}   ${s.translit}\n\ngloss: ${s.gloss}\n${s.definition}`
        : `(missing Strong's: ${tw.strongs})`
      return {
        headerLeft, headerRight,
        body,
        footerLeft: `${idx + 1} / ${tagged.length}`,
        footerRight: 'tap: next'
      }
    }
    case 'crossrefs': {
      if (!verse.crossRefs.length) return { headerLeft, headerRight, body: '(no cross-refs)', footerLeft: '', footerRight: '' }
      const idx = Math.min(state.crossRefIndex, verse.crossRefs.length - 1)
      const lines: string[] = []
      for (let i = 0; i < verse.crossRefs.length; i++) {
        const c = verse.crossRefs[i]!
        const marker = i === idx ? '>' : ' '
        lines.push(`${marker} ${c.ref}`)
        lines.push(`   ${truncate(c.preview, 38)}`)
      }
      return {
        headerLeft, headerRight,
        body: lines.join('\n'),
        footerLeft: `${idx + 1} / ${verse.crossRefs.length}`,
        footerRight: 'tap: next'
      }
    }
  }
}

function truncate(s: string, n: number): string {
  return s.length <= n ? s : s.slice(0, n - 1) + '…'
}
