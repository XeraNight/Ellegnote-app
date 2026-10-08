# Encore (iOS first, Android later)

Premium SwiftUI app for competitive ballroom dancers, couples, coaches and studios. Backend: Supabase (Postgres + RLS, Realtime, Auth, Edge Functions). Local data: SwiftData. UI strings are Slovak; keep them in one place.

## Scope
- Work on `Encore/` (iOS), `EncoreWigdet*` (widget, the typo is real, don't rename), `supabase/`.
- `web/` is reworked elsewhere (Antigravity). Do not read or edit it unless asked.
- `.archive/` is dead code. Never read or edit.

## Commands
Xcode is not the active developer dir, so prefix with `DEVELOPER_DIR`:
- Build: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Encore.xcodeproj -scheme Encore -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- Test: same command with `-scheme EncoreTests` and `test` (the Encore scheme has no test action).

## How to work
- Touching more than 2 files, or any structural change: write an outline first and wait for approval (Apple docs as the reference).
- Small steps. Build after each change. Don't say "done" without a build.
- Never change DB schema, RLS or migrations without showing the SQL first.
- Don't rename or move files or targets. New files in `Encore/` and `EncoreTests/` appear in Xcode and build automatically (synchronized folders), so just create them. Don't hand-edit `project.pbxproj` (targets, build settings).
- One change per commit. Never force-push.

## Code rules
- Native Apple frameworks first; no new packages without asking.
- SwiftUI small views, typed models, async/await, `@MainActor` for UI state, no force-unwraps on user or network data.
- Nothing heavy on the main thread (I/O, Keychain, Supabase, audio). No Keychain or LAContext calls inside view bodies.
- Reuse existing components. No duplicated code, no dead code.
- Keep iOS and backend contracts aligned; Android may come later.
- Use `Logger` (Logger+Encore.swift), never `print`. Never log tokens or personal data.

## Security (non-negotiable)
- No secrets in client code or git. Service-role key only in Edge Functions. Anon key is public, so RLS on every table.
- Never store passwords. Auth session lives in the Supabase SDK Keychain storage.
- Invite/QR tokens: random, short-lived, revocable, no personal data.

## Design
- Encore Crimson/Gold on Obsidian, Art Deco feel on brand screens, calmer flat variant on tool screens. Tokens in `Colors.swift`. Avoid a generic "AI look".
- Brand details: `BRAND_GUIDELINES.md`. Every screen follows §1A (the Home style: velvet background, glass cards, gold caps headers, micro-interactions, Slovak text styles). Reuse the components it lists.

## Domain
- Competition data comes from KSIS. Never invent competition rules or class-promotion numbers.
- Dancer identity is the personal KSIS number; the pair number belongs to the pair.
- Plans are Free, Plus and Premium, always personal (no group or studio plans). "Trainer" is a role, not an account type, and never follows from the plan.

## Token-saving habits (Pro plan)
- Don't read the big docs by default. Open only the one that matches the task:
  - `app.md`: current app state and screens
  - `SECURITY.md`: RLS, owner/Studio grants, Wallet certs
  - `docs/SUPABASE_LIBRARY_AND_REALTIME_SPEC.md`, `docs/CANVAS_*`: canvas and realtime
  - `docs/KSIS_*`: competitions
  - `docs/HOME_RADIAL_HUB_AND_RIVE_SPECIFICATION.md`: Home hub
  - `docs/AUTH_AUDIT.md` + `MOZNE_CHYBY.md` (kategória VII): login, registration and account edge cases, score and fix order
  - `docs/LAUNCH_PLAN.md`: current launch plan (Home, Plán, library, gating)
  - `LEGAL_AND_COMPLIANCE_CHECKLIST.md`, `MOZNE_CHYBY.md`: release and edge cases
- Use `rg` and read file ranges, not whole files. Use an Explore subagent for wide searches.
- One task per session; `/clear` between unrelated tasks. Default to Sonnet; use plan mode only for multi-file work.
