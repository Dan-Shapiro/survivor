# Requirements — Engineering Translation

What the software needs to do to support the game described in [GAME_DESIGN.md](./GAME_DESIGN.md). Filled in after (or alongside) the game design, once rules are clear enough to translate into features.

## Users & Accounts
- Login is **email + 4-digit PIN** (kept minimal instead of a full password). Players also set a **display name** for themselves.
- Host generates an invite link/code for a season; new players sign up (email + PIN + display name) via that link.
- Email doubles as both login identity and the address used for notifications (see Notifications).
- No cross-season persistent account system needed yet beyond this login (single host-run seasons); revisit if this grows.
- **PIN recovery**: no self-serve reset flow — a player who forgets their PIN asks the host, who can manually allow/trigger a PIN reset for them.

## Host/Admin Tools
The host is not a player and needs tools to run the season end-to-end:
- Create a season, generate/share the invite link, assign players into starting tribes. Enforce a **minimum of 12 players** at season start (supports the default 3-finalist / 9-juror worst case).
- Configure each round's challenge, choosing a **result-entry mode** per challenge: *in-app (auto-scored — deferred, not in v1)*, *input scores*, or *input winner only*. Also **set/schedule the deadline** (host-configurable per round).
- Enter challenge results per the chosen mode (scores or just the winner) once the challenge closes.
- Trigger/oversee the merge from tribes into one group.
- **Manually grant an idol** to any player, at the host's discretion. (In-app clue-based idol hunt is deferred to a future version.)
- **Post an announcement**, picking a **type**: Challenge Open / Challenge Close / Vote Open / Vote Close (schedulable alongside round deadlines), or Reminder / Update / General (sendable at any time, not tied to round schedule). Scheduling is always **one-time** — no recurring announcements.
- Close a round once the deadline passes — **rounds can auto-close**, with the **host able to override** (extend, close early, etc.).
- Reveal vote results (tally + any idol play — who played it, on whom) and confirm the eliminated player. **The host can see individual votes** (who voted for whom) — the one exception to the secret ballot, since the host needs full visibility to run the game credibly.
- **Set jury size** for the season — defaults to 9, host can override.
- **Manually remove a player** from the game (for chronic inactivity or mid-season quitting).
- **Allow a player to reset their PIN** (manual recovery flow, no self-serve reset).

## Player Experience
Core screens/flows a player needs:
- View current tribe/roster and season status (round number, pre-/post-merge).
- Participate in the current challenge (play in-app game, or submit proof) before the deadline.
- See immunity result (safe tribe/player).
- Cast a secret vote (if eligible/at risk that round) before the deadline.
- View tribal council results (vote tally and who was eliminated — never who voted for whom; idol plays show who played it and who it was played on).
- Check/use a found idol or advantage.
- In-app private/group messaging (DMs and alliance group chats).
- View host announcements.
- (Post-elimination) view-only access as a jury member, and cast a jury vote at the finale.

**Spectators** (eliminated players and/or outsiders) get **limited, read-only visibility**:
- ✅ Can see: challenge results, game-wide/public chat, voting results (tally, eliminations, idol plays — same as players, never individual vote choices), host announcements (all types).
- ❌ Cannot see: private DMs/alliance chats, who voted for whom (only the host can see this).

## Timing Model
- **Async with deadlines.** Each round opens a window during which players complete the challenge and cast votes on their own schedule.
- Deadline length is **configurable by the host per round**, with the ability to **schedule** rounds/deadlines in advance.
- Rounds **auto-close** at the deadline, with the **host able to override** (close early or extend).
- Missed deadline = auto-forfeit for that round only (no challenge score / vote doesn't count), per [GAME_DESIGN.md](./GAME_DESIGN.md#edge-cases).

## Notifications
- **Email notifications** for key events: new challenge/round opened, deadline approaching, tribal council results, idol granted, new DM/message, host announcement posted (of any type).
- Email is already collected as part of login (see Users & Accounts), so no separate capture step is needed.
- Cost note: keep to a free-tier email sending service given the casual/informal scale.

## Platform
- **Web app, mobile-friendly** (responsive) — no native app. Players should be able to comfortably complete challenges, vote, and chat from a phone browser.

## MVP Scope
- **v1 = full core loop, kept simple**: tribes, async challenges (input-scores and input-winner modes only), immunity, secret voting with revote ties, idols/advantages (host manual grant only), merge, jury finale, in-app messaging, spectator view, and typed host announcements — all included in v1, but each piece implemented as simply as possible (e.g. host does more manual work rather than building elaborate automation).
- **Explicitly deferred** (not in v1, revisit later): in-app auto-scored challenges (and the catalog of specific games), and the in-app clue-based idol hunt.
- Otherwise nothing else deferred yet — revisit once technical planning surfaces effort/complexity per feature (chat is the next most likely candidate to simplify further if needed).

## Open Questions / Decisions Log
_None open right now — all prior questions resolved._
