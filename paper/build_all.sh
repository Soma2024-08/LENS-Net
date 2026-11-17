#!/usr/bin/env bash
# Refresh every analysis, table and PDF (LENS-Net NCC + journal drafts). Safe to rerun any time.
set -e
cd "$(dirname "$0")"
PY=python3
L=../lensnet
CUDA_VISIBLE_DEVICES="" $PY $L/scripts/analyze_main.py > $L/logs/analyze.out 2>&1
CUDA_VISIBLE_DEVICES="" $PY $L/scripts/analyze_baselines_pooled.py > $L/logs/analyze_A1.out 2>&1
CUDA_VISIBLE_DEVICES="" $PY $L/scripts/analyze_baselines_rwf.py > $L/logs/analyze_A2.out 2>&1
CUDA_VISIBLE_DEVICES="" $PY $L/scripts/analyze_scfd_scvd.py > $L/logs/analyze_fresh.out 2>&1
$PY make_tables.py
./figs_to_png.sh
for d in ncc_draft journal_draft; do
  $PY build_refs.py $d
  ../../paper_src/tectonic $d.tex > $d.log 2>&1 || { echo "$d FAILED"; grep -i error $d.log | head; exit 1; }
  echo "$d: $($PY -c "from pypdf import PdfReader;print(len(PdfReader('$d.pdf').pages))") pages"
done
