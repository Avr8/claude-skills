---
name: md-to-doc
description: Convert Markdown files into clean Word (.docx) or PDF documents with tables, code blocks, headings and a table of contents intact, using pandoc plus a fallback chain for PDF engines. Use this whenever someone wants to turn a .md / README / notes / report into a Word doc or PDF, "export this markdown", "make this a docx", "send this as a PDF", batch-convert a folder of markdown, or complains that tables broke when converting — even if they don't mention pandoc.
---

# Markdown → Word / PDF

Turn Markdown into a document someone can open, print, or attach — without mangled tables.

## Why this skill exists

Pandoc handles `.md → .docx` well with zero extra dependencies. PDF is where people get stuck: pandoc needs a PDF engine (LaTeX, weasyprint, wkhtmltopdf, typst…) and most machines have none. Guessing wastes minutes and produces cryptic errors. So: detect what's installed first, then pick the path that will actually work.

## Workflow

1. **Locate input(s)** and decide output format. If the user said "doc"/"Word" → `.docx`. "PDF" → `.pdf`. Unsure → `.docx` (it always works) and mention PDF is available.
2. **Run the bundled script** — it does detection and fallbacks for you:
   ```bash
   bash <skill-dir>/scripts/md2doc.sh input.md output.docx
   bash <skill-dir>/scripts/md2doc.sh input.md output.pdf
   bash <skill-dir>/scripts/md2doc.sh notes/ out/ pdf      # whole folder
   ```
   Add `--toc` to include a table of contents (good for anything with 3+ headings), `--reference-doc style.docx` to apply a corporate Word template.
3. **Report** the output path and which engine was used. If the script fell back (e.g. docx → PDF via Word or LibreOffice), say so in one line.

## PDF engine order (what the script tries)

| Order | Engine | Notes |
|---|---|---|
| 1 | `typst` | Fast, single binary, good tables. `brew install typst` |
| 2 | `xelatex` / `lualatex` / `pdflatex` | Best typography; handles Unicode best with xelatex |
| 3 | `weasyprint` / `wkhtmltopdf` | HTML-based; CSS-styleable |
| 4 | docx → PDF via **LibreOffice** (`soffice --headless`) | Cross-platform fallback |
| 5 | docx → PDF via **Microsoft Word** (macOS AppleScript) | Works on most Macs with Office |

If none exist, produce the `.docx`, and tell the user the one-line install that would unlock PDF (`brew install typst` on macOS is the lightest).

## Table hygiene (the most common complaint)

Before converting, skim the Markdown for these and fix them in a temp copy (don't edit the user's source unless asked):
- Pipe tables need a header separator row (`|---|---|`) — without it pandoc renders plain text.
- A blank line is required before a table that follows a paragraph.
- Very wide tables (6+ columns) overflow PDF pages: suggest landscape (`-V geometry:landscape` for LaTeX) or the docx route.
- Literal `|` inside a cell must be escaped as `\|`.

## Word-on-macOS gotchas (built into the script, listed in case you script it yourself)

- Word is sandboxed. Opening or saving outside paths it has been granted (e.g. `/tmp`) pops a "Grant File Access" dialog and the script hangs. Stage files in `~/Library/Containers/com.microsoft.Word/Data/` and move the PDF out afterwards.
- Address the document as `active document`, not `document "name.docx"` — the name form fails with error -1708.
- Cold-starting Word can time out (-1712) even though it's opening. Wait until Word answers a trivial Apple Event, then open, wait, and `save as` in a separate call; retry with a longer wait.
- Use `save as … file format format PDF` (not `save as2`). Wrap every `osascript` call in a timeout so a dialog can never hang the session.
- Cold start takes ~60s; warm ~15s. Tell the user it's working rather than going silent.

## Don't

- Don't try to install heavy system libraries (pango/gobject for weasyprint, full TeX Live) without asking — it can take 10+ minutes. Offer the light option instead.
- Don't overwrite an existing output file silently; if it exists, write `name (1).docx` or ask.
