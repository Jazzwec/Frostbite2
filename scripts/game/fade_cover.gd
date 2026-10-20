class_name FadeCover
extends RefCounted
## Things that hide Meagan from the camera (tree crowns, buildings) fade out while she's behind
## them, and back in when she leaves. A fading mesh gets its own see-through copy of its material
## (the mobile renderer ignores GeometryInstance3D.transparency), and its shared material back
## once it's solid again.

## How see-through a covering thing gets (0 = solid, 1 = gone): 30% opacity.
const FADED := 0.7
## How quickly it fades out (as she steps behind) and back in (per second): out fast, in gently.
const SPEED_OUT := 5.5
const SPEED_IN := 3.0
## Meagan's body on screen: from her feet up this far, in metres, and this wide either side.
const BODY_HEIGHT := 1.9
const BODY_HALF_WIDTH := 0.4


## Whether an upright thing standing at `base`, `height` tall and `radius` wide, covers Meagan
## (standing at `meagan`) as seen by a camera at `camera` (looking down its -Z).
static func covers(camera: Transform3D, meagan: Vector3, base: Vector3, height: float, radius: float) -> bool:
	var to_cam := camera.affine_inverse()
	var her_feet := to_cam * meagan
	var her_head := to_cam * (meagan + Vector3(0, BODY_HEIGHT, 0))
	var foot := to_cam * base
	var top := to_cam * (base + Vector3(0, height, 0))
	# It has to be nearer the camera than she is.
	if foot.z <= her_feet.z + 0.2:
		return false
	if absf(foot.x - her_feet.x) > radius + BODY_HALF_WIDTH:
		return false
	# Do their heights on screen overlap?
	return minf(top.y, her_head.y) > maxf(foot.y, her_feet.y)


## Eases every mesh under `root` towards faded (or solid). True while any of it is still faded.
static func fade(root: Node, faded: bool, delta: float) -> bool:
	var goal := FADED if faded else 0.0
	var any := false
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var t: float = mi.get_meta("fade", 0.0)
		if t == goal:
			any = any or t > 0.0
			continue
		t = move_toward(t, goal, (SPEED_OUT if goal > t else SPEED_IN) * delta)
		mi.set_meta("fade", t)
		if t > 0.0:
			if not mi.has_meta("solid"):
				var solid := mi.material_override as StandardMaterial3D
				if solid == null:
					continue
				mi.set_meta("solid", solid)
				# A see-through crown shouldn't still throw a solid shadow over her.
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var see_through := solid.duplicate() as StandardMaterial3D
				see_through.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
				mi.material_override = see_through
			var m := mi.material_override as StandardMaterial3D
			m.albedo_color.a = (mi.get_meta("solid") as StandardMaterial3D).albedo_color.a * (1.0 - t)
			any = true
		elif mi.has_meta("solid"):
			mi.material_override = mi.get_meta("solid")
			mi.remove_meta("solid")
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return any
