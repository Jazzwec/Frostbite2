# Fight v2: research notes (2026-10-20)

What the web research found, and where each finding was applied.

## Findings

- **Every attack needs a readable wind-up, with enough time to react.** Unclear attacks are poor communication, not difficulty. If the gap between telegraph and hit is too short, lengthen the telegraph.
  - *Applied:* wind-ups of 0.65 to 1.2 s, set after review 1.
- **A tell's prominence should scale with its damage.**
  - *Applied:* tell outline width by kind.
- **Red alone reads poorly. An animated "acceleration" toward the strike shows both its timing and direction.**
  - *Applied:* a dark-rust edge, plus a wash that advances to the edge as the strike comes.
- **A tell's colour must not overlap another state's.** For example, grey read as "invulnerable".
  - *Applied:* rust is used for tells only. Meagan's sweep is cream-gold, and the hit flash is a warm rim.
- **The visuals should match the actual hit areas.**
  - *Applied:* the stick's stroke is drawn at exactly the reach and arc the engine hits with.
- **Hit-stop of about 50–100 ms goes on heavy hits only.** Screen shake should scale with the hit's strength, and constant shake tires players.
  - *Applied:* no hit-stop on Meagan's automatic attacks, and shake only for bear swipes, troll slams and shards.
- **Flashes should be short, and a primary confirmation should be paired with one secondary flourish.**
  - *Applied:* an 80 ms rim flash, plus ink flecks and a snow burst.

## Sources

- https://gamedeveloper.com/design/enemy-attacks-and-telegraphing
- https://choostgames.com/blog/what-makes-a-good-boss-fight/
- https://itch.io/jam/gedg-progress-day-1/rate/1035402
- https://uhiyama-lab.com/en/notes/unity/unity-game-feel-hit-feedback/
- https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/
- https://www.wayline.io/blog/making-combat-feel-impactful
- Earlier steer: https://forums.fatsharkgames.com/t/darktide-101-enemy-character-art-dev-blog/105178 (silhouette first)
