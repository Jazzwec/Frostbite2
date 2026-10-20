#!/bin/bash
# A frame strip from the running game, for a ChatGPT review of something that moves.
#   tools/capture/strip.sh OUTDIR NAME FRAMES GAP "setup gdscript"
# Runs the setup in the game (swallowtail runtime eval), waits 2 s, takes FRAMES screenshots GAP
# seconds apart, and joins the middle of each (where the camera keeps Meagan) into a 3-wide grid
# at OUTDIR/NAME.png. Run from the project root with the game playing.
OUTDIR=$1; NAME=$2; N=$3; GAP=$4; SETUP=$5
FRAMES=$OUTDIR/frames
mkdir -p "$FRAMES"
swallowtail runtime eval --code "$SETUP" >/dev/null 2>&1
sleep 2
for i in $(seq 1 "$N"); do
  swallowtail runtime screenshot --save_path "$FRAMES/${NAME}_$i.png" >/dev/null 2>&1
  sleep "$GAP"
done
python - "$OUTDIR" "$NAME" "$N" <<'PY'
import sys
from PIL import Image
out, name, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
ims = [Image.open(f"{out}/frames/{name}_{i}.png").convert("RGB") for i in range(1, n + 1)]
w, h = ims[0].size
box = (int(w * 0.1), int(h * 0.28), int(w * 0.9), int(h * 0.66))
crops = [im.crop(box) for im in ims]
cw, ch = crops[0].size
cols = min(n, 3)
rows = (n + cols - 1) // cols
sheet = Image.new("RGB", (cw * cols, ch * rows), (255, 255, 255))
for i, c in enumerate(crops):
    sheet.paste(c, ((i % cols) * cw, (i // cols) * ch))
sheet.save(f"{out}/{name}.png")
PY
rm -f "$FRAMES/${NAME}"_*.png
rmdir "$FRAMES" 2>/dev/null
echo "$NAME done"
