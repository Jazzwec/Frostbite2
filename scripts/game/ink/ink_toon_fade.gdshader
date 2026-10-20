shader_type spatial;
// ink_toon, see-through: what FadeCover swaps in while a tree or building is faded so Meagan
// shows through it.
render_mode depth_prepass_alpha;

#define INK_FADE
#include "res://scripts/game/ink/ink_toon_body.gdshaderinc"
