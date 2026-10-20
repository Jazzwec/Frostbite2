**6/10 overall.** Readability **5.5**, feel/juice **5.5**, design depth/progression **7.5**, phone UX **5.5**. The combat asks for precise movement, but the presentation makes threat, timing and consequences too difficult to read. Feel is provisional: frame strips, especially slowed ones, cannot establish how responsive combat actually feels.

These show different situations, not a clear before/after. Bear and troll attacks read better in isolation than the mixed wave or outpost. The raider’s thin targeting line is substantially weaker. The full screens expose the biggest issue: interface elements compete with the space needed to steer.

All pixel sizes below refer to the supplied **540 × 960** phone view; scale proportionally.

1. **Make attack timing and danger unmistakable. Highest score impact.**  
   **What I see:** Thin rust outlines and pale washes disappear into snow, shadows and overlapping bodies. The troll’s expanding fill is difficult to distinguish between frames. Raider shards resemble ambient snow particles.  
   **Why it hurts:** Steering is the player’s only combat input; seeing where and when to dodge is the essential interaction.  
   **Change:** Give hostile zones a **3 px dark-rust boundary**, a **12–18% rust wash**, and a clearly advancing fill. Start with **0.65 s wolf/fox, 0.9 s bear, 1.2 s troll, 1.0 s shard** wind-ups. Lock aim for the final **0.3 s**, then resolve exactly within the displayed shape. Make shard landing circles at least **36 px across** and projectiles **10–14 px long**, dark-edged. Keep Meagan’s attack sweep cream-gold so ownership is immediate.

2. **Return the centre of the phone to movement.**  
   **What I see:** The wave announcement, large navigation arrow, four utility buttons and stockpile reminder occupy separate bands. The Armory sheet leaves much of this competing interface visible.  
   **Why it hurts:** Threats and escape routes must remain visible around both Meagan and the player’s thumb.  
   **Change:** Consolidate resources and wave status into the top **110 px**. Move music, sound and DEV into one menu. Replace the two-line wave banner with a **44 px-high strip**, visible for **1.5 s**, then collapse it into the forecast. Replace the stockpile toast with a small bag indicator beside resources. Suppress navigation arrows and combat banners while the Armory sheet is open; pause combat during this modal.

3. **Make automatic weapon choice predictable through Meagan’s pose.**  
   **What I see:** Mixed-wave frames show stick sweeps, hits and reward text in the same small area; the screenshots do not explain when snowballs become melee.  
   **Why it hurts:** When players cannot choose attacks, unpredictable target selection feels like lost control.  
   **Change:** As a starting point, enter melee at **1.0× stick reach**, return to ranged beyond **1.25× reach**, and hold a valid target for at least **0.4 s**. Commit attack direction at the start of a **0.12–0.18 s anticipation**. Show a raised stick for melee readiness and a visible snowball for ranged readiness. Keep the **100° sweep and three-target cap**, but make the visible arc match the actual hit area exactly.

4. **Replace full-body hit flashes with readable contact and recovery.**  
   **What I see:** Struck wolves become nearly white outlines; the bear and troll strips show little unmistakable separation between impact and recovery. “+1 Mat” can dominate the hit itself.  
   **Why it hurts:** Players need to recognise “my hit landed,” “I was hit” and “now I can approach” without reading text.  
   **Change:** Use a **70–90 ms warm rim flash**, **4–6 px recoil** and a small directional ink burst. Give bear and troll attacks **0.45 s and 0.7 s recovery poses** respectively. Add distinct attack and player-damage sounds. Avoid global hit-stop on every automatic hit; reserve a brief accent for heavy impacts. Aggregate loot text over **0.5 s** and place it away from faces and health bars.

5. **Turn theft into an obvious, recoverable pursuit.**  
   **What I see:** The theft strip contains several overlapping Food deductions, sack badges, a downed Meagan and an unrelated “Upgrade” label. The escape and recovery opportunity are not evident.  
   **Why it hurts:** Losing resources while incapacitated can read as punishment without a useful next action.  
   **Change:** Suppress nearby interaction labels during theft. Use one store-level message—**“23 Food stolen—catch the thieves”**—and **22–26 px sack badges** on fleeing enemies. Give loaded thieves a distinct retreat pose and **20% movement penalty**. Mark only the nearest loaded thief at the screen edge. On defeat, visibly return the stolen resources toward the store before updating the counter.

6. **Separate enemy roles and outpost states through silhouette.**  
   **What I see:** Wolves and foxes overlap into narrow dark shapes; the bear and troll rely heavily on round greybox parts. Outpost raiders cluster behind posts, with no clear sleeping-versus-active distinction.  
   **Why it hurts:** Players need to choose an escape direction before identifying individual enemies in a crowd.  
   **Change:** Make foxes low and long-tailed, wolves broad-shouldered, bears wide and low, and trolls tall with oversized forearms. Use modest size differences: approximately **0.8 / 1.0 / 1.5 / 1.8× wolf footprint**. Separate active enemies by roughly **0.7 body widths** where possible. Sleeping defenders should sit with lowered weapons and one shared sleep marker; waking should include a **0.8 s stand-up cue**. Fade foreground posts when they obscure actors.

7. **Make progression decisions legible and validate the failure loop.**  
   **What I see:** The Armory lists several stat changes, while the supplied simulation establishes survival under two upgrade schedules. It does not establish whether players understand the necessary spending or can recover from mistakes.  
   **Why it hurts:** A late breach feels arbitrary if the player cannot connect upgrades, incoming threats and resource loss.  
   **Change:** Put three aligned rows in the sheet: **Snowball damage, Sweep damage, Guard damage / HP**. Show costs with owned amounts and highlight shortages. Give **8–10 s notice** before a wave, including enemy-role icons and a distinct troll warning. Playtest missed upgrades, one theft and one knockdown—not just ideal purchasing. Target a recoverable first breach; avoid one theft immediately cascading into departures and furnace failure.

**For 9/10:** On an actual phone at normal speed, a new player should recognise each attack’s safe direction, predict Meagan’s weapon choice, understand how to recover stolen supplies, and choose an upgrade without explanation. Mixed waves must preserve those qualities under thumb occlusion. More enemy types or upgrade levels will not close that gap.

Verdict: fix first — threat readability, screen obstruction and theft recovery currently weaken the player’s only active skill: steering.