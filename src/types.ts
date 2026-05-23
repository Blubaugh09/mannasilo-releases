export type Testament = 'OT' | 'NT'

export interface StrongsEntry {
  /** Strong's number, e.g. "G2316" (Greek) or "H7225" (Hebrew). */
  number: string
  /** Original-language form (Greek or Hebrew script). */
  original: string
  /** Latin-letter transliteration. */
  translit: string
  /** Short gloss (1–3 words). */
  gloss: string
  /** One-line definition. */
  definition: string
}

export interface TaggedWord {
  /** The English word as it appears in the verse. */
  word: string
  /** Strong's reference, omitted for grammatical particles. */
  strongs?: string
}

export interface CrossRef {
  ref: string
  preview: string
}

export interface Verse {
  id: string
  reference: string
  testament: Testament
  text: string
  words: TaggedWord[]
  crossRefs: CrossRef[]
  commentary: string[]
}

export type ScreenMode = 'verse' | 'strongs' | 'crossrefs' | 'commentary'

export interface AppState {
  verseId: string
  mode: ScreenMode
  page: number
  /** Index into verse.words filtered to tagged entries — only used in 'strongs' mode. */
  wordIndex: number
  /** Index into verse.crossRefs — only used in 'crossrefs' mode. */
  crossRefIndex: number
}
