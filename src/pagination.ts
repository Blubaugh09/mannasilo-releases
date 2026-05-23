/**
 * Naive word-wrap paginator sized for the G2 display.
 * 576×288 at our chosen body font fits ~36 chars/line and ~6 lines/page comfortably
 * once we leave room for a header (reference) and footer (page indicator).
 */
const DEFAULT_LINE_CHARS = 36
const DEFAULT_LINES_PER_PAGE = 6

export interface PaginateOptions {
  lineChars?: number
  linesPerPage?: number
}

export function paginate(text: string, opts: PaginateOptions = {}): string[] {
  const lineChars = opts.lineChars ?? DEFAULT_LINE_CHARS
  const linesPerPage = opts.linesPerPage ?? DEFAULT_LINES_PER_PAGE

  const lines: string[] = []
  for (const paragraph of text.split(/\n+/)) {
    if (!paragraph.trim()) {
      lines.push('')
      continue
    }
    const words = paragraph.split(/\s+/)
    let line = ''
    for (const w of words) {
      if (!line.length) {
        line = w
        continue
      }
      if (line.length + 1 + w.length > lineChars) {
        lines.push(line)
        line = w
      } else {
        line += ' ' + w
      }
    }
    if (line) lines.push(line)
  }

  const pages: string[] = []
  for (let i = 0; i < lines.length; i += linesPerPage) {
    pages.push(lines.slice(i, i + linesPerPage).join('\n'))
  }
  return pages.length ? pages : ['']
}

export function paginateChunks(chunks: string[], opts: PaginateOptions = {}): string[] {
  return paginate(chunks.join('\n\n'), opts)
}
