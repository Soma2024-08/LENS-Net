#!/usr/bin/env python3
"""Write refs_<stem>.tex: the entries of refs.tex that <stem>.tex cites, in order of first citation (IEEE style).
Fails if a cited key has no entry."""
import re, sys
from pathlib import Path
stem = sys.argv[1]; tex = Path(f"{stem}.tex").read_text()
tex = re.sub(r"\\tabin\{([^}]+)\}", lambda m: Path(m.group(1)).read_text(), tex)   # tables pulled in by \tabin
tex = re.sub(r"(?m)^%.*$", "", tex)
order = []
for grp in re.findall(r"\\cite\{([^}]+)\}", tex):
    for k in grp.split(","):
        k = k.strip()
        if k not in order: order.append(k)
items = {re.match(r"\\bibitem\{([^}]+)\}", it).group(1): it.strip() for it in re.split(r"(?=\\bibitem\{)", Path("refs.tex").read_text()) if it.strip().startswith("\\bibitem")}
missing = [k for k in order if k not in items]
if missing: sys.exit(f"cited but missing: {missing}")
out = [items[k] for k in order]
if stem.startswith("ncc"):                      # NCC page limit: omit DOIs (IEEE allows it; venue/volume/pages are kept)
    out = [re.sub(r",?\s*doi:\S+?(?=\.?\s*$)", "", it.rstrip()) for it in out]
    out = [re.sub(r"\s*arXiv:\S+?(?=\.?\s*$)", "", it) if re.search(r"\\emph\{(?!arXiv)", it) else it for it in out]   # venue given: drop arXiv id
out = [re.sub(r"\.\.$", ".", it.rstrip()) for it in out]   # no double full stop after trimming
Path(f"refs_{stem}.tex").write_text("\n\n".join(out) + "\n")
print(f"refs_{stem}.tex: {len(order)} references in citation order")
