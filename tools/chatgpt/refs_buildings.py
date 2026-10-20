"""Makes the ink references for the buildings and town pieces (model pipeline, phase C), one after
another, through chatgpt.py on gpt-6-astra. Each uses the round-3 lineup and the approved Storehouse
as style references, so the set matches. Skips any that already exist.

    python tools/chatgpt/refs_buildings.py [name ...]
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = (
    "Rendered in INK AND WATERCOLOUR PICTURE-BOOK style: hand-inked slightly wobbly dark outlines, soft "
    "watercolour colour washes with visible paper grain, gently simplified shapes, like a Nordic children's "
    "picture book brought into a 3D game with toon shading and outlines. Palette: Falu red #B2412E, ochre "
    "#C9973F, faded teal #5E8A87, snow #EEF2F2, blue shadow #7F93A6, deep ink #2C3440, firelight #F2B266. "
    "Designed like a real indie game's art style with deliberate simplification and restraint: few materials, "
    "large clean colour areas, no surface texture noise, no rendered glow or bloom, no sparkles, no glossy "
    "plastic, no generic 3D animated-movie look, no over-detailed props, no text, no labels, no UI. SUBJECT: "
)
HOUSE = (
    " Same building family as the attached storehouse: vertical timber walls in one flat colour mass with a few "
    "broad darker battens, dark brown corner posts, a low base of a few large grey fieldstones, a steep gable "
    "roof completely covered by a thick soft rounded snow cap hanging over the eaves in a few broad lumps with "
    "the dark wooden roof edge just showing, gable end facing the viewer, walls clearly visible and the roof "
    "not overwhelming them. Readable from a high game camera (pilot review, 2026-10-20): only a short snow "
    "overhang at the front so the gable and sign stay clear, an oversized sign with one bold simple symbol, "
    "chunky corner posts about a tenth of the facade width, a few large foundation stones, broad door leaves; "
    "three clear value groups (light snow, mid-tone walls, dark warm-brown timber); no nails, no fine plank "
    "grain, no scratches, no painted crevice shadows."
)
PROP = (
    " Same world as the attached buildings: chunky simplified shapes, broad flat watercolour colour areas in "
    "two or three tones, thick soft snow, no fine texture, no nails, no grain, no scratches. A small game prop "
    "that must read at phone size from a high camera."
)
SUBJECTS = {
    "house_lumber_yard": "the LUMBER YARD: an open-fronted Nordic woodshed, dark-stained timber, packed full of neatly stacked round log ends facing the viewer, a chopping stump with an axe in front to one side, a snowy roof on chunky posts. About 3.2 m wide, 2.4 m deep, 3.4 m tall." + HOUSE,
    "house_hunting_lodge": "the FISHING LODGE: a faded-teal (#5E8A87) timber cottage with an ochre-brown door, two warm glowing windows, a hanging sign with a simple painted fish motif, two wooden barrels and a coil of rope by the side wall, a short rack with two hanging fish. About 3 m wide, 2.6 m deep." + HOUSE,
    "house_workshop": "the WORKSHOP: a natural brown timber workshop with a deep-teal door, a fieldstone chimney on one side of the roof, a hanging sign with a simple painted hammer motif, a chunky iron anvil on a stump and a crate beside the door. About 3 m wide, 2.6 m deep." + HOUSE,
    "house_barracks": "the BARRACKS: a taller, narrower Falu-red (#B2412E) timber guardhouse, deep-teal door, one warm window, a hanging sign with a simple painted round shield motif, a wooden rack of four spears leaning against the side wall. About 2.8 m wide, 2.6 m deep, walls 2.8 m tall." + HOUSE,
    "house_bunkhouse": "the BUNKHOUSE: a long cosy ochre (#C9973F) timber house with a deep-teal door, two warm glowing windows either side, a hanging sign with a simple painted pair-of-mittens motif, a small log bench by the door. About 3.3 m wide, 2.6 m deep." + HOUSE,
    "house_kitchen": "the KITCHEN: a Falu-red (#B2412E) timber cookhouse with an ochre-brown door, one warm window, a fieldstone chimney, a hanging sign with a simple painted furnace-mouth motif (a dome with an arched fire mouth), a big black iron cooking pot on a small fire beside the door. About 3 m wide, 2.6 m deep." + HOUSE,
    "house_watchtower": "the WATCHTOWER: a tall wooden lookout tower on four chunky timber legs with cross braces, a small faded-teal hut enclosing the bottom with an ochre door, a railed platform at the top under a pointed four-sided roof thickly capped with snow, a small Falu-red flag on top. About 2.4 m wide, 8 m tall. Same family as the attached storehouse (timber, fieldstone base, thick soft snow).",
    "house_hot_springs": "the HOT SPRINGS bath hut: a small faded-teal (#5E8A87) timber bathhouse with an ochre door, a hanging sign with a simple painted three-wavy-lines motif, a thin wisp of steam from a small roof vent. Only the hut, no pool. About 2.4 m wide, 2.2 m deep." + HOUSE,
    "furnace": "the VILLAGE FURNACE, the heart of the town: a squat round fieldstone-and-iron oven about 4 m across, made of a FEW LARGE rounded grey fieldstones in two flat tones, a rust-brown iron dome on top, a short brick chimney, a big arched fire mouth at the front glowing warm orange with a few logs inside, a small stack of firewood leaning at one side, the furnace-mouth motif painted once on the iron. Chunky and readable, not busy.",
    "prop_stove": "a SMALL BORDER STOVE: a squat round fieldstone stove about 1.5 m across and 1.8 m tall, a few large grey stones, a dark iron dome lid, a short iron chimney pipe, a small arched fire mouth at the front glowing warm orange. Same family as a village furnace, much smaller and simpler.",
    "prop_den": "a WOLF DEN: a low rocky mound of a few big dark grey boulders, thick snow settled on its back and top, a dark cave mouth at the front, a few gnawed sticks by the entrance, no animals. About 3.3 m wide and 1.6 m tall.",
    "prop_stockpile": "the town STOCKPILE: a low open log platform about 3.4 m wide and 1.4 m deep with a simple post-and-rail rack along the back, divided into three empty bays by short dividers, snow along the top rail and the post tops. Empty: no goods on it.",
    # Phase D: props, trees and chests. Rocks: a few broad faces and one connected snow cap (pilot review).
    "prop_rock_a": "a SNOWY BOULDER: one big rounded grey fieldstone with a smaller rock leaning against its right side, each stone made of three to five BROAD flat faces in two grey tones, one thick CONNECTED snow cap covering the upper half of both, a small snow drift round their foot. About 1.5 m wide, 0.8 m tall." + PROP,
    "prop_rock_b": "a LOW CLUSTER OF THREE SNOWY STONES: one medium rounded grey stone and two small ones beside it, each of a few broad flat faces in two grey tones, one connected snow cap on their tops, a small drift round their foot. About 1.5 m wide, 0.55 m tall." + PROP,
    "boulder": "a LARGE SNOWY BOULDER: a single big rounded grey rock with a few broad flat faces in two grey tones and a thick connected snow cap over its top half, a small drift at its foot. About 2 m wide and 1.2 m tall." + PROP,
    "prop_fence": "ONE SECTION OF RUSTIC WOODEN FENCE: two chunky round dark-brown posts with snow caps, two thick split-log rails between them, a ridge of snow along the top rail, seen side-on. About 2 m long, 1.1 m tall." + PROP,
    "prop_woodpile": "a NEAT WOODPILE: chunky split logs stacked in a low pile, round pale log ends facing the viewer, a soft snow cap on top, a small drift at its foot. About 1.3 m wide, 0.9 m tall." + PROP,
    "prop_boat": "a SMALL WOODEN ROWING BOAT frozen into ice, seen from slightly above and to the side: a chunky brown plank hull, two bench seats, one oar resting inside, a little snow lying in its bottom. About 2.1 m long." + PROP,
    "prop_jetty": "a SHORT WOODEN JETTY: a plank walkway on four chunky round posts, the planks in two warm-brown tones, snow along its boards and on the post tops, seen from slightly above. About 2.4 m long, 1.1 m wide, 0.7 m tall." + PROP,
    "prop_shrub": "a BARE WINTER SHRUB: a small fan of dark-brown bare twigs rising from a little mound of snow, a few blobs of snow caught on the twigs. About 0.7 m tall." + PROP,
    "prop_lantern_post": "a WOODEN LANTERN POST: a chunky dark-brown wooden post about 1.8 m tall with a short arm at the top from which hangs a black iron lantern glowing warm amber, snow on top of the lantern and the arm." + PROP,
    "prop_sled": "a WOODEN SLED: a low wooden sled with light-wood slats, two dark iron runners curling up at the front and a coil of rope at the front, seen from slightly above. About 1.6 m long." + PROP,
    "prop_bench": "a LOG BENCH: a thick half-log seat resting on two short round log stumps, a ridge of snow along the seat. About 1.5 m long, 0.6 m tall." + PROP,
    "crate": "a STURDY WOODEN CRATE: a chunky light-brown plank crate with a darker cross-brace on each side, a snow cap on top. About 0.7 m on each side." + PROP,
    "log": "ONE CHUNKY CUT LOG lying on its side: brown bark in broad flat areas, a pale round cut end with two rings, a little snow on top. About 1 m long." + PROP,
    "pine_a": "a TALL SNOWY PINE TREE: a dark blue-green conifer with three or four chunky stacked tiers of foliage, thick snow resting on each tier, a short brown trunk at the bottom. About 3.5 m tall." + PROP,
    "pine_b": "a FULL SNOWY PINE TREE: a dark blue-green conifer, slightly wider, with four chunky stacked tiers of foliage, heavy snow on each tier, a short brown trunk. About 3.5 m tall." + PROP,
    "pine_c": "a SMALL SQUAT SNOWY PINE TREE: a young dark blue-green conifer with two or three chunky tiers of foliage, thick snow on top, a short brown trunk. About 2.5 m tall." + PROP,
    "chest_cache": "a ROPE-TIED SUPPLY CRATE for a treasure cache: a chunky wooden crate with a flat lid, tied with thick rope crossing over the lid, snow on the lid corners. About 1 m wide, 0.7 m deep, 0.75 m tall. The lid is a separate flat slab on top." + PROP,
    "chest_boon": "a TREASURE CHEST: a chunky faded-teal (#5E8A87) wooden chest with broad ochre (#C9973F) metal bands, a rounded barrel lid and a big ochre lock plate on the front, a little snow on the lid. About 1 m wide, 0.65 m deep, 0.85 m tall. The rounded lid sits on top of the box." + PROP,
    "chest_gear": "an IRON-BANDED GEAR CHEST: a chunky dark charcoal-brown wooden chest with broad pale-grey iron bands and corner plates, a flat lid, a heavy iron hasp on the front, a little snow on the lid. About 1 m wide, 0.65 m deep, 0.75 m tall. The lid is a separate slab on top." + PROP,
}


def main():
    names = sys.argv[1:] or list(SUBJECTS)
    for name in names:
        out = ROOT / "source_art" / "concept" / "ink" / f"{name}.png"
        if out.exists():
            print("exists", out)
            continue
        cmd = [sys.executable, str(ROOT / "tools" / "chatgpt" / "chatgpt.py"), "image", TEMPLATE + SUBJECTS[name], "--for-3d",
               "--ref", str(ROOT / "source_art" / "direction" / "round3" / "inked" / "lineup.png"),
               "--ref", str(ROOT / "source_art" / "concept" / "ink" / "house_storehouse.png"), "--out", str(out)]
        run = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
        print(name, "ok" if run.returncode == 0 else "FAILED " + run.stderr[-300:], flush=True)


if __name__ == "__main__":
    main()
