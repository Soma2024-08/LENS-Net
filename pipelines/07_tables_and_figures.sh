#!/usr/bin/env bash
# Stage 7 - tables (numbers.tex, tables/*.tex) and 400-dpi figures for the paper, from the result files only.
set -e; cd "$(dirname "$0")/../paper"; PY=${PY:-python}
$PY make_tables.py
$PY make_figures.py; $PY fig_efficiency.py; $PY fig_robust.py; $PY fig_prompts.py; $PY fig_categories.py; $PY fig_evidence.py; $PY tsne_fig.py
bash figs_to_png.sh
