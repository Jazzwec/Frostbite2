"""Renames a rig's bones to Mixamo's, the names the game's ModelRig looks up (mixamorig_<Bone> in
Godot, from mixamorig:<Bone> in Blender). Tripo rigs already use them; Meshy rigs don't.

Run inside Blender (through the Blender MCP), usually via cleanup_character in cleanup.py:

    exec(open(r"C:/Claude Code/Frostbite2/tools/blender/rig_names.py", encoding="utf-8").read())
    print(to_mixamo(bpy.data.objects["Armature"]))

Meshy's skeleton (checked on a rigged Jan, 2026-10-20) has Mixamo's limb names without a prefix,
but its spine runs the other way round: Hips -> Spine02 -> Spine01 -> Spine -> neck, where
Mixamo has Hips -> Spine -> Spine1 -> Spine2 -> Neck. So Meshy's "Spine" is the chest, and only
renaming by prefix would make the game bend Jans at the chest instead of the waist.
"""

MIXAMO_PREFIX = "mixamorig:"

# Meshy bone -> Mixamo bone. Bones not listed keep their name and just get the prefix.
MESHY_TO_MIXAMO = {
    "Spine02": "Spine",
    "Spine01": "Spine1",
    "Spine": "Spine2",
    "neck": "Neck",
    "head_end": "HeadTop_End",
}


def to_mixamo(armature):
    """Renames the bones in place (vertex groups follow); returns a summary. Safe to run twice."""
    bones = armature.data.bones
    if any(b.name.startswith(MIXAMO_PREFIX) for b in bones):
        return f"{armature.name}: already Mixamo-named"
    # Two passes, so Meshy's "Spine" -> "Spine2" can't collide with "Spine02" -> "Spine".
    old_names = [b.name for b in bones]
    for name in old_names:
        bones[name].name = "__tmp__" + name
    for name in old_names:
        bones["__tmp__" + name].name = MIXAMO_PREFIX + MESHY_TO_MIXAMO.get(name, name)
    return f"{armature.name}: renamed {len(old_names)} bones to Mixamo names"
