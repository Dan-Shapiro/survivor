# Game Design — [Season/Game Name TBD]

Source of truth for what the game is and how it plays. Written from the product owner/SME's perspective — no implementation details here.

## Vision
Friends aren't in the same physical place, so the app IS the venue for the game — challenges, voting, and tribal council all happen through the app itself, not in person or over a side group chat.

## Players & Roles
- **Host**: a single person runs the game — creates the season, manages challenges, judges/enters results, advances rounds, and can make **announcements** to the group (immediately or scheduled). The host does **not** play as a contestant and is not at risk of elimination.
- **Players**: contestants competing in the season.
- **Spectators**: eliminated players and/or outsiders can follow along with **limited, read-only visibility** — challenge results, public/game-wide chat, voting results (tally, eliminations, idol plays), and host announcements. They never see private DMs/alliance chats or who voted for whom (see [REQUIREMENTS.md](./REQUIREMENTS.md#player-experience) for the full breakdown). The host is the one exception to "who voted for whom" — see Voting & Tribal Council below.

## Season Structure
- Players start split into 2+ **tribes** and compete tribe-vs-tribe.
- Partway through the season, tribes **merge** into a single tribe and play continues individually.
- Timing is **async with deadlines**: each round has a window for players to complete challenges/vote in their own time. Deadline length is **configurable by the host per round** and can be **scheduled** in advance; rounds **auto-close** at the deadline, with the host able to override (extend or close early).

## Core Round Loop
Classic sequence, pre-merge:
1. **Challenge** — tribes compete against each other.
2. **Immunity** — the winning tribe is safe for the round; the losing tribe goes to tribal council.
3. **Vote** — members of the losing tribe vote out one of their own.
4. **Tribal Council** — votes are revealed/tallied; lowest-voted (most-voted-against) player is eliminated.

Post-merge sequence (individual play):
1. **Challenge** — players compete individually.
2. **Individual immunity** — the winner cannot be voted out this round, but still participates in voting like everyone else.
3. **Vote** — all remaining players vote (including the immune player).
4. **Tribal Council** — votes revealed/tallied; the most-voted player is eliminated (votes against the immune player, if any, don't count toward elimination).

## Challenges
Per challenge, the host picks how results get entered:
- **In-app (auto-scored)** — an in-app game (trivia, puzzle, etc.) that scores itself. **Deferred** — not part of v1; the catalog of specific in-app games is a future decision.
- **Input scores** — host manually enters a score per player, for challenges happening outside the app (e.g. a timed task) that are still scoreable.
- **Input winner only** — host just records who won, with no per-player scores.

Scores, when collected, are informational only — they don't drive any game mechanic beyond determining the winner for that round's immunity. A challenge that only records a winner works exactly the same as one with full scores.

## Voting & Tribal Council
- **Ballot**: secret ballot from the players'/spectators' point of view — each eligible player picks one person to vote out; only the final tally is ever shown to players and spectators, plus whether an idol was played, who played it, and who it was played on. Individual votes are **never** shown to other players or spectators, at any point, including after the game ends.
- **The host can see how each person voted.** This is a deliberate exception to the secret-ballot rule — the host needs full visibility to run the game credibly — but it does not extend to anyone else.
- **Idols/advantages**: exist and can cancel votes against the holder (classic hidden immunity idol behavior). For v1, the only way to get one is a **host manual grant** — the host awards an idol to a player directly (e.g. because they found/earned one outside the app, or at the host's discretion). An in-app clue-based hunt (fair, app-driven opportunity for any player to find one) is a **deferred** future feature — exact mechanics not designed yet.
- **Ties**: if two or more players are tied for most votes, there's a **revote** — everyone except the tied players votes again, choosing only among the tied players, repeating until the tie breaks.

## Alliances & Social Features
- The app includes **in-app private/group messaging** — players can DM or form alliance group chats within the app itself, rather than relying on outside tools.
- _Note: this is a meaningfully larger build than game mechanics alone (real-time-ish messaging, group membership). Flag for MVP-scope discussion in REQUIREMENTS.md — may be worth a simple v1 (e.g. basic text DMs/group threads) rather than a full chat product._

## Host Announcements
The host can broadcast an **announcement** to the group. Distinct from alliance/DM chat: one-directional, host-to-everyone. Announcements have a **type**:
- **Round-lifecycle types** (Challenge Open, Challenge Close, Vote Open, Vote Close) — tied to a round's timing and can be **scheduled** in advance alongside that round's deadlines.
- **Freeform types** (Reminder, Update, General) — the host can send these **at any time**, not tied to a round's schedule.

All scheduling is **one-time only** — no recurring announcements. Spectators can see all announcements, same as players.

## Scoring & Win Condition
- Classic **jury vote** finale: once the season narrows to a final few players, the jury votes for who should win based on how they played. Highest jury votes wins the season.
- **Only post-merge eliminations join the jury** (classic-show rule) — a player voted out before the merge is simply out of the game, not a juror.
- **Jury size defaults to 9**, but is configurable by the host. Because only post-merge boots are jurors, the actual jury size depends on how many players are eliminated after the merge — 9 is the upper bound reachable with 12 starting players (e.g. if the host merges early), not a guarantee.
- **Minimum starting group size is 12** — enough for 3 finalists plus up to 9 post-merge eliminations in the best case for jury size.

## Edge Cases
- **Missed deadline / inactivity**: if a player misses a round's deadline (doesn't complete a challenge or doesn't vote), it's an **auto-forfeit** for that round only — no challenge score and/or their vote doesn't count — but they are not automatically removed from the game.
- **Chronic inactivity / quitting mid-season**: the **host can manually remove a player** from the game at any time.
