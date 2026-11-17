#!/usr/bin/env bash
# Download and unpack the per-window predictions of every model (93 MB, 801 MB unpacked).
#   bash reproduce/get_predictions.sh                         # download the release asset
#   bash reproduce/get_predictions.sh /path/to/lensnet_predictions.tar.xz   # use a local copy
# Unpacks into workspace/ and source_benchmark/ at the repository root, where every analysis script looks.
set -euo pipefail
cd "$(dirname "$0")/.."

URL="https://github.com/Soma2024-08/LENS-Net/releases/download/v1.0/lensnet_predictions.tar.xz"
SHA256="b48a455266922266ca1109c9bd97c693332578831feba0485fc3b31d8bc1582d"
FILE="${1:-lensnet_predictions.tar.xz}"

if [ ! -f "$FILE" ]; then
  echo "Downloading $URL"
  curl -L --fail -o "$FILE" "$URL"
fi

echo "Checking SHA-256 ..."
echo "$SHA256  $FILE" | sha256sum -c -

echo "Unpacking ..."
tar -xJf "$FILE"

# The result summaries live in results/ only: the analysis scripts read them through workspace/.
ln -sfn ../results workspace/logs
for f in results/revision/*; do ln -sfn "../../$f" "workspace/review/$(basename "$f")"; done
echo "Done. Predictions are in workspace/ and source_benchmark/. Next: python reproduce/verify_paper.py"
