#!/usr/bin/env bash
# md2doc.sh — convert Markdown to .docx or .pdf with engine detection + fallbacks.
# Usage:
#   md2doc.sh <input.md> <output.docx|output.pdf> [--toc] [--reference-doc file.docx]
#   md2doc.sh <input-dir> <output-dir> <docx|pdf> [--toc]
set -euo pipefail

die() { echo "md2doc: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

have pandoc || die "pandoc not found. Install: brew install pandoc  (or https://pandoc.org/installing.html)"

[[ $# -ge 2 ]] || die "usage: md2doc.sh <in.md> <out.docx|out.pdf> [--toc] | <in-dir> <out-dir> <docx|pdf>"
IN="$1"; OUT="$2"; shift 2

FMT=""
if [[ -d "$IN" ]]; then
  [[ $# -ge 1 ]] || die "folder mode needs a format: docx or pdf"
  FMT="$1"; shift
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Default Word template: pandoc's own, plus visible table borders and a shaded header row.
# Pandoc's stock tables have no borders, which is why tables "look broken" in Word.
REFDOC="$SKILL_DIR/assets/reference.docx"
CSS="$SKILL_DIR/assets/print.css"

EXTRA=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --toc) EXTRA+=(--toc) ;;
    --reference-doc) REFDOC="$2"; shift ;;
    --no-style) REFDOC="" ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

COMMON=(--from=markdown+pipe_tables+grid_tables+yaml_metadata_block+task_lists --standalone)

to_docx() { # in out
  local in="$1" out="$2" ref=()
  [[ -n "$REFDOC" && -f "$REFDOC" ]] && ref=(--reference-doc "$REFDOC")
  # --resource-path: resolve relative images from the input file's own directory.
  pandoc "$in" "${COMMON[@]}" ${EXTRA[@]+"${EXTRA[@]}"} ${ref[@]+"${ref[@]}"} --resource-path="$(dirname "$in")" -o "$out"
}

find_chrome() {
  local c
  for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
           "/Applications/Chromium.app/Contents/MacOS/Chromium" \
           "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
           "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"; do
    [[ -x "$c" ]] && { echo "$c"; return 0; }
  done
  for c in google-chrome google-chrome-stable chromium chromium-browser microsoft-edge; do
    have "$c" && { command -v "$c"; return 0; }
  done
  return 1
}

html_to_pdf_chrome() { # md pdf — pandoc → standalone HTML with print CSS → headless browser
  local chrome; chrome="$(find_chrome)" || return 1
  local tmp; tmp="$(mktemp -d)"
  local html="$tmp/doc.html" out_abs
  out_abs="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
  local title; title="$(basename "${1%.*}")"
  pandoc "$1" "${COMMON[@]}" ${EXTRA[@]+"${EXTRA[@]}"} --embed-resources --resource-path="$(dirname "$1")" \
    --metadata pagetitle="$title" ${CSS:+--css "$CSS"} -t html5 -o "$html" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  "$chrome" --headless=new --disable-gpu --no-pdf-header-footer --user-data-dir="$tmp/profile" \
    --print-to-pdf="$out_abs" "file://$html" >/dev/null 2>&1 || "$chrome" --headless --disable-gpu \
    --print-to-pdf-no-header --user-data-dir="$tmp/profile" --print-to-pdf="$out_abs" "file://$html" >/dev/null 2>&1
  rm -rf "$tmp"
  [[ -s "$out_abs" ]]
}

docx_to_pdf_libreoffice() { # docx pdf
  local soffice=""
  if have soffice; then soffice=soffice
  elif [[ -x "/Applications/LibreOffice.app/Contents/MacOS/soffice" ]]; then soffice="/Applications/LibreOffice.app/Contents/MacOS/soffice"
  else return 1; fi
  local outdir; outdir="$(cd "$(dirname "$2")" && pwd)"
  "$soffice" --headless --convert-to pdf --outdir "$outdir" "$1" >/dev/null 2>&1 || return 1
  local produced="$outdir/$(basename "${1%.*}").pdf"
  [[ "$produced" == "$(cd "$(dirname "$2")" && pwd)/$(basename "$2")" ]] || mv -f "$produced" "$2"
}

docx_to_pdf_word() { # docx pdf  (macOS only)
  [[ "$(uname)" == "Darwin" ]] || return 1
  [[ -d "/Applications/Microsoft Word.app" ]] || return 1
  # Word is sandboxed: it can't silently read/write arbitrary paths (e.g. /tmp) and
  # will block on a "Grant File Access" dialog. Its own container is always allowed,
  # so stage the files there and move the PDF out afterwards.
  local stage="$HOME/Library/Containers/com.microsoft.Word/Data/md2doc-$$"
  mkdir -p "$stage" || return 1
  local name; name="$(basename "${1%.*}")"
  cp "$1" "$stage/$name.docx"
  local in_abs="$stage/$name.docx" pdf_abs="$stage/$name.pdf"
  run_as() { # script, timeout seconds — never let osascript hang the caller
    osascript -e "$1" >/dev/null 2>&1 & local pid=$!
    ( sleep "$2"; kill "$pid" 2>/dev/null ) & local watchdog=$!
    wait "$pid"; local rc=$?
    kill "$watchdog" 2>/dev/null; wait "$watchdog" 2>/dev/null
    return $rc
  }
  run_as 'tell application "Microsoft Word" to activate' 60 || true
  # Cold start: wait until Word answers Apple Events before opening anything.
  for _ in $(seq 1 30); do
    run_as 'tell application "Microsoft Word" to get name' 5 && break
    sleep 2
  done
  local ok=1
  for attempt in 1 2 3; do
    run_as "tell application \"Microsoft Word\" to open (POSIX file \"$in_abs\")" 60 || true
    sleep $((4 + attempt * 3))
    if run_as "tell application \"Microsoft Word\"
  with timeout of 60 seconds
    set theDoc to active document
    save as theDoc file name \"$pdf_abs\" file format format PDF
    close theDoc saving no
  end timeout
end tell" 90 && [[ -f "$pdf_abs" ]]; then ok=0; break; fi
  done
  [[ $ok -eq 0 ]] && mv -f "$pdf_abs" "$2"
  rm -rf "$stage"
  return $ok
}

to_pdf() { # in out
  local in="$1" out="$2" rp=(--resource-path="$(dirname "$in")")
  if have typst; then
    pandoc "$in" "${COMMON[@]}" ${EXTRA[@]+"${EXTRA[@]}"} "${rp[@]}" --pdf-engine=typst -o "$out" 2>/dev/null && { echo "engine: typst"; return 0; }
  fi
  for eng in xelatex lualatex pdflatex; do
    if have "$eng"; then
      pandoc "$in" "${COMMON[@]}" ${EXTRA[@]+"${EXTRA[@]}"} "${rp[@]}" --pdf-engine="$eng" -V geometry:margin=1in -o "$out" 2>/dev/null && { echo "engine: $eng"; return 0; }
    fi
  done
  for eng in weasyprint wkhtmltopdf; do
    if have "$eng"; then
      pandoc "$in" "${COMMON[@]}" ${EXTRA[@]+"${EXTRA[@]}"} "${rp[@]}" --pdf-engine="$eng" -o "$out" 2>/dev/null && { echo "engine: $eng"; return 0; }
    fi
  done
  # Headless Chrome/Edge/Chromium is on most machines and renders tables with borders via CSS.
  if html_to_pdf_chrome "$in" "$out"; then echo "engine: HTML -> PDF via headless browser"; return 0; fi
  # Fallback: go through docx.
  local tmp; tmp="$(mktemp -d)"; local docx="$tmp/$(basename "${out%.*}").docx"
  to_docx "$in" "$docx"
  if docx_to_pdf_libreoffice "$docx" "$out"; then echo "engine: docx->pdf via LibreOffice"; rm -rf "$tmp"; return 0; fi
  if docx_to_pdf_word "$docx" "$out"; then echo "engine: docx->pdf via Microsoft Word"; rm -rf "$tmp"; return 0; fi
  local keep="${out%.*}.docx"; mv "$docx" "$keep"; rm -rf "$tmp"
  echo "md2doc: no PDF engine available. Wrote $keep instead." >&2
  echo "md2doc: lightest fix: brew install typst   (or install LibreOffice)" >&2
  return 2
}

convert_one() { # in out
  local in="$1" out="$2"
  case "${out##*.}" in
    docx) to_docx "$in" "$out" && echo "wrote: $out" ;;
    pdf)  to_pdf "$in" "$out" && echo "wrote: $out" ;;
    *) die "output must end in .docx or .pdf: $out" ;;
  esac
}

if [[ -n "$FMT" ]]; then
  [[ "$FMT" == docx || "$FMT" == pdf ]] || die "format must be docx or pdf"
  mkdir -p "$OUT"
  shopt -s nullglob
  files=("$IN"/*.md)
  [[ ${#files[@]} -gt 0 ]] || die "no .md files in $IN"
  rc=0
  for f in "${files[@]}"; do convert_one "$f" "$OUT/$(basename "${f%.md}").$FMT" || rc=$?; done
  exit $rc
else
  [[ -f "$IN" ]] || die "input not found: $IN"
  convert_one "$IN" "$OUT"
fi
