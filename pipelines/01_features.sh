#!/usr/bin/env bash
# Stage 1 - frozen features (paper: Method, Sec. "Frozen encoders").
# CLIP ViT-L/14 (and ViT-B/16 for the Lite variants) prompt signals + VideoMAE-B motion features for every window set.
set -e; cd "$(dirname "$0")/.."; PY=${PY:-python}
SETS="bench external fresh conf cfights conf2"                  # c3_* and fl* chunks are built by stages 4 and 5
for s in $SETS; do
  LENS_BACKBONE=L14 $PY src/features/extract_compact.py --set $s --psets orig,para,surv,broad   # prompt sets: Sec. "Sensitivity to the prompt set"
  LENS_BACKBONE=B16 $PY src/features/extract_compact.py --set $s                                # Lite variants L2/L3
  $PY src/features/extract_vmae.py $s
done
