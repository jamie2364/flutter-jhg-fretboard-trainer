# Fretboard Trainer — Pre-Release Break Test Report

Date: 2026-10-27
Scope: how a user could break the app or push it into a bad state (double-taps, rapid actions, edge cases). Analysis only — no code changed.

---

## Summary verdict

Very solid on the gameplay side — one of the most carefully guarded controllers in the suite. Every answer path (Name the Note/Interval/Chord, Build modes, Chord Lab) blocks a second tap while feedback is showing, so spamming answers can't double-score. Timers always cancel the previous one before starting a new one (so no runaway double-speed clock), you can never turn off all six strings, and every "advance to next question" waits and checks the game is still running so it can't fire after you leave or reset.

Two issues remain, and both are shared-code patterns seen in the sister apps rather than anything unique here.

---

## Findings (most important first)

### 1. Deleting a folder that has folders inside it hides them for good — MEDIUM
- Where: Saved Sessions / Library — deleting a folder.
- Why: sessions sitting directly in the deleted folder are safely moved back to the root, but **sub-folders inside it are not**. They keep pointing at the deleted parent and disappear from the Library, taking their sessions with them.
- User impact: a user who nests folders and deletes a top one silently loses everything nested below.
- Note: this is the same bug found in Ear Training; Backing Tracks and Velocity already handle it correctly, so there's a proven fix to copy.

### 2. Double-tapping a saved session can resume without your score/clock — LOW/MEDIUM
- Where: tapping a saved-session tile to resume it.
- Why: resuming stashes the saved progress and then replaces the screen, with no guard. A fast double-tap replaces the board twice — and because the stashed progress is consumed by the first board that builds, the second one can come up as a fresh session instead of your restored score and timer.
- User impact: occasional — a resumed session that lands empty instead of where you left off. Recoverable by resuming again, and your saved copy isn't touched.

---

## Things that are already solid (checked, no issue)
- All answer handlers (note / interval / chord / chord-lab, name + build) — block a second tap during feedback; no double-scoring.
- "Next question" advances — every one waits a beat and re-checks the game is still running, so none fires after reset or leaving.
- Timers — countdown / count-up / leaderboard all cancel any existing timer before starting, so a double-tap can't run two clocks; countdown length is floored so it can't end instantly.
- String selection — can't turn off the last active string.
- Reveal Answer — guarded in every mode; can't reveal twice or after the round is answered.
- Chord catalog still loading on first play — the round starts cleanly once it's ready.
- Restored sessions — land paused and apply saved score/clock after the board's own reset, so the restore isn't clobbered (see finding 2 for the double-tap edge).

---

## Suggested priority (if/when you want fixes)
1. Fix folder delete to also lift sub-folders up to the root (copy the Backing Tracks / Velocity behaviour) — fixes finding 1, the only data-loss risk.
2. Add a short guard to the saved-session resume so a double-tap can't navigate twice — fixes finding 2.

Both are small, localized changes. Say the word and I'll implement.
