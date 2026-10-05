@AGENTS.md

# Encore (web companion)

Premium iOS app (SwiftUI) plus a separate Next.js web app for competitive ballroom dancers, couples, coaches and clubs. Backend is Supabase (Postgres with RLS, realtime, auth, Edge Functions). Auth: email/password, Google Sign-In, Face ID via Keychain.

## Layout

- `../Encore.xcodeproj` — iOS app; see the repo-root `CLAUDE.md` for iOS rules and build commands (the "Wigdet" typo in the widget target is real; don't rename)
- `web/` — Next.js app, deployed on Vercel, separate from the iOS app. Being reworked in Antigravity.
- `.archive/` — old, unused code. Never read or edit.

## Commands

- Web: `cd web && npm install && npm run dev | build | lint`

## How to work

- For anything touching more than 2 files: write a plan first and wait for my approval.
- Work in small steps. Build and run tests after each change. Don't say "done" without running them.
- Never change DB schema, RLS or migrations without showing me the SQL first.
- Don't rename or move files or Xcode targets without asking. Editing `project.pbxproj` is risky: tell me to add new files in Xcode instead.
- One change per commit with a clear message. Never force-push. Another tool may be editing on a different branch.

## Security (non-negotiable)

- No secrets in client code or in git. The Supabase service-role key lives only in Edge Functions or server env. `.env` files are never committed.
- RLS on every table. Users see only their own data and what is shared with them (partner, coach, studio membership).
- Wallet pass signing certificates and keys stay server-side only.
- QR/invite tokens: random, short-lived, revocable, containing no personal data. Rate-limit invite and token endpoints.
- Validate input on the server. Don't log personal data or tokens.

## Code quality

- SwiftUI with small views, typed models, async/await, no force unwraps. Keep logic out of views.
- Reuse existing components. No duplicated code.
- The backend is the shared source of truth, so keep iOS and web API contracts in sync. Android may come later.
- UI text is currently Slovak. Keep strings in one place.

## Design

- Art Deco system: oxblood/black with gold, ornamental serif headings on brand screens, a calmer flatter variant on tool screens (metronome, canvas, speed trainer).
- Avoid generic, templated "AI look".

## Domain rules

- Competition data comes from KSIS (szts.ksis.eu). Read exactly what it shows. Never invent competition rules or class-promotion numbers from memory; use KSIS data or a rules table with a source and a date.
- Dancer identity is the personal KSIS number. The pair number belongs to the current pair, not to the person.
- Studio plan: the subscription belongs to the studio. "Trainer" is a role in a studio membership, not a separate account type.
