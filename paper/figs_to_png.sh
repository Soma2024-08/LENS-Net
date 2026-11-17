#!/usr/bin/env bash
# Every paper figure as a 600-dpi PNG (user requirement; was 400 dpi before the single-column journal): TikZ diagrams via their standalone files, plots from the
# vector PDFs written by the figure scripts. The drafts include only figs/*.png.
set -e
cd "$(dirname "$0")"
TT=${TECTONIC:-tectonic}
for s in arch paradigm; do
  $TT ${s}_standalone.tex > /dev/null 2>&1
  pdftoppm -r 600 -png -singlefile ${s}_standalone.pdf figs/fig_${s}
done
for f in figs/fig_*.pdf; do                     # every plot written by the figure scripts
  b=${f%.pdf}
  case $b in figs/fig_arch|figs/fig_paradigm) continue;; esac
  pdftoppm -r 600 -png -singlefile $f $b
done
echo "600-dpi PNGs written: $(ls figs/fig_*.png | wc -l)"
