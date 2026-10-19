# NOTES

What felt wrong while playing, and what's still open. This file is the prompt for the next session.

## Felt wrong while playing

_(nothing logged yet)_

## Next session: design pass for Frostbite2

Before writing game code, agree these with the user and write the answers into `docs/design-brief.md` (rewrite its Tech & build plan and Art & assets sections for Godot):

- **What changes from Frostbite 1?** "Rebuild fresh" was chosen, so list what to keep, drop and add. Frostbite 1's open items are in `docs/frostbite1/NOTES.md` (roster of 7 Jans vs the brief's 10–12, the Canteen idea, the untested pacing).
- **Camera and controls in 3D:** fixed isometric or rotatable/zoomable, tap-to-walk, drag-to-pan.
- **Art direction for 3D:** how Meagan and the Jans get made (Tripo from photos or a description, then rigged in Blender), the building style, how many tier looks per building.
- **Music and sound:** what ElevenLabs should make (theme, ambient loops, blizzard track, effects) and how it gets into the project.
- **Phases:** a new phase list for Godot, like Frostbite 1's seven.
- **Test framework:** GUT or gdUnit4.
- **Git hosting:** create `Jazzwec/Frostbite2` on GitHub when there's something to share; Git LFS if model and audio files get large.

## Setup still missing

- Android export: Godot 4.7.2 export templates, a JDK and the Android SDK.
- Windows export: export templates.
